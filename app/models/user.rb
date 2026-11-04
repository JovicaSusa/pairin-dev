class User < ApplicationRecord
  include ImageUploader::Attachment(:image) # adds an `image` virtual attribute
  #TODO: Temp, move this when separate model for prog languages is created
  LEVELS = %w(expert proficient competent advanced_beginner novice).freeze
  # Not legal advice: see the "Minimum-age requirements for Pairin" research.
  MINIMUM_AGE = 16
  ADULT_AGE = 18
  # Starting points for rate limits, meant to be changed as we learn.
  NEW_ACCOUNT_AGE = 7.days
  NEW_ACCOUNT_APPLICATIONS_PER_DAY = 5
  MESSAGES_PER_HOUR = 60
  # How long a suspended account can be put right before it's deleted.
  SUSPENSION_GRACE_PERIOD = 14.days
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  # Deleting an account deletes every conversation the person was in, on either
  # side, including the other person's messages. The privacy policy promises this.
  has_many :pair_requests, dependent: :destroy
  has_many :offers, foreign_key: :offerer_id, dependent: :destroy
  has_many :participations, foreign_key: :participant_id, dependent: :destroy
  has_many :activities, foreign_key: :receiver_id, dependent: :destroy, inverse_of: :receiver
  has_many :sessions, through: :participations, source: :participable, source_type: Session.name
  has_many :availability_windows, dependent: :destroy
  has_many :blocks_made, class_name: "Block", foreign_key: :blocker_id, dependent: :destroy, inverse_of: :blocker
  has_many :blocks_received, class_name: "Block", foreign_key: :blocked_id, dependent: :destroy, inverse_of: :blocked

  # Messages from the other person since this user last opened each conversation,
  # as { offer_id => count }.
  def unread_message_counts
    Message
      .joins(offer: :pair_request)
      .where("offers.offerer_id = :id OR pair_requests.user_id = :id", id:)
      .where.not(sender_id: id)
      .where(<<~SQL.squish, id:)
        messages.created_at > COALESCE(
          CASE WHEN offers.offerer_id = :id THEN offers.offerer_read_at ELSE offers.poster_read_at END,
          '-infinity'
        )
      SQL
      .group(:offer_id)
      .count
  end

  # Everyone this user can't see or apply to, whichever of them did the blocking.
  def blocked_user_ids
    blocks_made.pluck(:blocked_id) + blocks_received.pluck(:blocker_id)
  end

  def blocked_with?(other)
    blocked_user_ids.include?(other.id)
  end

  # Ends every conversation between them, and tells the other person nothing.
  # Returns those conversations.
  def block!(other)
    transaction do
      blocks_made.find_or_create_by!(blocked: other)

      Offer.between(self, other).includes(:partnership).to_a.each do |offer|
        offer.partnership&.end!(by: self)
        offer.not_a_match!(by: self)
      end
    end
  end

  def application_limit_reached?
    created_at > NEW_ACCOUNT_AGE.ago && offers.where(created_at: 1.day.ago..).count >= NEW_ACCOUNT_APPLICATIONS_PER_DAY
  end

  def message_limit_reached?
    Message.where(sender: self, created_at: 1.hour.ago..).count >= MESSAGES_PER_HOUR
  end

  def display_name
    name.presence || "A Pairin member"
  end

  validates :language, inclusion: { in: I18nData.languages.keys }, allow_nil: true
  validates :country, inclusion: { in: I18nData.countries.keys }, allow_nil: true
  validates :level, inclusion: { in: LEVELS }, allow_nil: true
  validates :date_of_birth, presence: true, on: :create
  validates :date_of_birth, comparison: { less_than_or_equal_to: -> { Date.current }, message: "can't be in the future" }, allow_nil: true
  validate :old_enough_for_an_account, on: :create, if: :under_age?
  # The age gate relies on it, so once given it stays put.
  validate :date_of_birth_unchanged, on: :update, if: -> { date_of_birth_changed? && date_of_birth_was.present? }
  # Only github.com links: this one is shown to other people and put in emails.
  normalizes :github_url, with: ->(url) {
    url = url.strip
    url.empty? || url.match?(%r{\A[a-z][a-z0-9+.-]*:}i) ? url.presence : "https://#{url}"
  }
  validate :github_url_is_a_github_link, if: :github_url?

  TIMEZONES = TZInfo::Timezone.all_identifiers.to_set.freeze

  validates :timezone, inclusion: { in: TIMEZONES, message: "isn't a known timezone" }, if: :timezone_changed?
  # Signup sends whatever the browser reports; an unknown zone shouldn't block the account.
  before_validation(on: :create) { self.timezone = "UTC" unless TIMEZONES.include?(timezone) }

  # Someone whose age we don't know yet is in neither group, so they can't see
  # or be seen by anyone until they've answered.
  scope :minors, -> { where(date_of_birth: (ADULT_AGE.years.ago.to_date + 1)..) }
  scope :adults, -> { where(date_of_birth: ..ADULT_AGE.years.ago.to_date) }

  def minor?
    date_of_birth.present? && date_of_birth > ADULT_AGE.years.ago.to_date
  end

  def adult?
    date_of_birth.present? && !minor?
  end

  def age_group
    return :minor if minor?

    :adult if adult?
  end

  def same_age_group?(other)
    age_group.present? && age_group == other.age_group
  end

  def same_age_group
    return User.minors if minor?

    adult? ? User.adults : User.none
  end

  # What other people may see of this person. Under-18s show only their name;
  # their learning topic is the partner search itself.
  def profile_for_others
    return { name: display_name, image_url: nil, profession: nil, level: nil, github_url: nil } if minor?

    { name: display_name, image_url:, profession:, level: level_titleized, github_url: }
  end

  scope :suspended_past_grace_period, -> { where(suspended_at: ..SUSPENSION_GRACE_PERIOD.ago) }

  # Their searches go Off straight away, so nobody sees them during the grace
  # period. The date they gave isn't kept.
  def suspend!
    transaction do
      update_columns(suspended_at: Time.current)
      pair_requests.switched_on.find_each(&:switch_off!)
    end
  end

  def suspended?
    suspended_at?
  end

  # Devise checks these on every request, so this also ends any other open session.
  def active_for_authentication?
    super && !suspended?
  end

  def inactive_message
    suspended? ? :suspended : super
  end

  def level_titleized
    level&.titleize
  end

  # Judged on today's date where the person is, so a birthday counts from its
  # local start. A future date isn't under age; it's a typo the form reports.
  def under_age?
    return false if date_of_birth.blank?

    today = Time.find_zone(timezone)&.today || Date.current

    date_of_birth <= today && !self.class.old_enough?(date_of_birth, today:)
  end

  private def github_url_is_a_github_link
    uri = URI.parse(github_url)
    valid = uri.is_a?(URI::HTTP) && %w(github.com www.github.com).include?(uri.host&.downcase) && uri.path.to_s.length > 1
    errors.add(:github_url, "must be a github.com link, like https://github.com/your-name") unless valid
  rescue URI::InvalidURIError
    errors.add(:github_url, "must be a github.com link, like https://github.com/your-name")
  end

  private def date_of_birth_unchanged
    errors.add(:date_of_birth, "can't be changed")
  end

  private def old_enough_for_an_account
    errors.add(:date_of_birth, "can't be used")
  end

  class << self
    # Turning 16 today counts. years_ago maps 29 Feb to 28 Feb in other years.
    def old_enough?(date_of_birth, today: Date.current)
      date_of_birth <= today.years_ago(MINIMUM_AGE)
    end

    def ransackable_attributes(auth_object=nil)
      ["level", "language"]
    end
  end
end
