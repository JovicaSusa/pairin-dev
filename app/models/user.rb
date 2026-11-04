class User < ApplicationRecord
  include ImageUploader::Attachment(:image) # adds an `image` virtual attribute
  #TODO: Temp, move this when separate model for prog languages is created
  LEVELS = %w(expert proficient competent advanced_beginner novice).freeze
  # Not legal advice: see the "Minimum-age requirements for Pairin" research.
  MINIMUM_AGE = 16
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  has_many :pair_requests, dependent: :destroy # TODO: Reconsider dependent option
  has_many :offers, foreign_key: :offerer_id, dependent: nil # TODO: Reconsider dependent option
  has_many :participations, foreign_key: :participant_id, dependent: nil # TODO: Reconsider dependent option
  has_many :sessions, through: :participations, source: :participable, source_type: Session.name
  has_many :availability_windows, dependent: :destroy

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
