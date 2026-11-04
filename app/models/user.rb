class User < ApplicationRecord
  include ImageUploader::Attachment(:image) # adds an `image` virtual attribute
  #TODO: Temp, move this when separate model for prog languages is created
  LEVELS = %w(expert proficient competent advanced_beginner novice).freeze
  # Not legal advice: see the "Minimum-age requirements for Pairin" research.
  MINIMUM_AGE = 16
  # How long a suspended account can be put right before it's deleted.
  SUSPENSION_GRACE_PERIOD = 14.days
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  has_many :pair_requests, dependent: :destroy
  has_many :offers, foreign_key: :offerer_id, dependent: :destroy
  has_many :participations, foreign_key: :participant_id, dependent: :destroy
  has_many :activities, foreign_key: :receiver_id, dependent: :destroy, inverse_of: :receiver
  has_many :sessions, through: :participations, source: :participable, source_type: Session.name
  has_many :availability_windows, dependent: :destroy

  validates :language, inclusion: { in: I18nData.languages.keys }, allow_nil: true
  validates :country, inclusion: { in: I18nData.countries.keys }, allow_nil: true
  validates :level, inclusion: { in: LEVELS }, allow_nil: true
  validates :date_of_birth, presence: true, on: :create
  validates :date_of_birth, comparison: { less_than_or_equal_to: -> { Date.current }, message: "can't be in the future" }, allow_nil: true
  validate :old_enough_for_an_account, on: :create, if: :under_age?
  # The age gate relies on it, so once given it stays put.
  validate :date_of_birth_unchanged, on: :update, if: -> { date_of_birth_changed? && date_of_birth_was.present? }
  TIMEZONES = TZInfo::Timezone.all_identifiers.to_set.freeze

  validates :timezone, inclusion: { in: TIMEZONES, message: "isn't a known timezone" }, if: :timezone_changed?
  # Signup sends whatever the browser reports; an unknown zone shouldn't block the account.
  before_validation(on: :create) { self.timezone = "UTC" unless TIMEZONES.include?(timezone) }

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
