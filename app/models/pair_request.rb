class PairRequest < ApplicationRecord
  include ActivityGeneratable

  belongs_to :user
  has_many :offers, dependent: nil # TODO: Reconsider
  has_one :accepted_offer, -> { accepted }, class_name: "Offer"
  # Legacy: requests used to own their time slots. Slots now come from the
  # poster's weekly hours (#bookable_slots) and offers own their booked period.
  has_many :periods, as: :periodable, dependent: :destroy, inverse_of: :periodable
  has_many :sessions, as: :sessionable
  has_many :taggings, as: :taggable
  has_many :tags, through: :taggings

  MAX_DURATION = 180

  validates :description, :subject, :duration, presence: true
  validates :duration, numericality: { greater_than: 0, less_than_or_equal_to: MAX_DURATION, message: "must be between 1 and #{MAX_DURATION} minutes" }

  scope :switched_on, -> { where(paused_at: nil) }

  # Signed token for the no-login "Turn it back on" link in the paused email.
  generates_token_for :resume, expires_in: 30.days

  accepts_nested_attributes_for :taggings,
    reject_if: ->(attrs) { attrs["tag_attributes"].blank? || attrs["tag_attributes"]["name"].blank? },
    allow_destroy: true
  accepts_nested_attributes_for :sessions, reject_if: :new_record?

  class << self
    def ransackable_associations(auth_object=nil)
      ["tags", "user"]
    end

    def ransackable_attributes(auth_object=nil)
      ["duration"]
    end
  end

  # Off requests are hidden from others and can't receive offers.
  def paused?
    paused_at?
  end

  # Toggling On/Off only touches paused_at, so it works even for older
  # requests that wouldn't pass today's validations.
  def switch_off!
    update_columns(paused_at: Time.current, updated_at: Time.current)
  end

  # A request is booked into the poster's weekly hours, so it can't be On
  # without them. Returns false when it stays Off.
  def switch_on!
    return false unless user.availability_windows.exists?

    update_columns(paused_at: nil, updated_at: Time.current)
  end

  def bookable_slots
    PairRequests::BookableSlots.call(self)
  end

  def has_accepted_offer?
    offers.accepted.exists?
  end
end
