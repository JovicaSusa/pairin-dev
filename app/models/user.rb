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

  validates :language, inclusion: { in: I18nData.languages.keys }, allow_nil: true
  validates :country, inclusion: { in: I18nData.countries.keys }, allow_nil: true
  validates :level, inclusion: { in: LEVELS }, allow_nil: true
  validates :date_of_birth, presence: true, on: :create
  validates :date_of_birth, comparison: { less_than_or_equal_to: -> { Date.current }, message: "can't be in the future" }, allow_nil: true
  TIMEZONES = TZInfo::Timezone.all_identifiers.to_set.freeze

  validates :timezone, inclusion: { in: TIMEZONES, message: "isn't a known timezone" }, if: :timezone_changed?
  # Signup sends whatever the browser reports; an unknown zone shouldn't block the account.
  before_validation(on: :create) { self.timezone = "UTC" unless TIMEZONES.include?(timezone) }

  def level_titleized
    level&.titleize
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
