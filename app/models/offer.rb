class Offer < ApplicationRecord
  include ActivityGeneratable

  belongs_to :offerer, class_name: "User"
  belongs_to :pair_request
  # History only: applications used to book a time. New ones have no period.
  has_one :period, as: :periodable, dependent: :destroy, inverse_of: :periodable, autosave: true

  HOW_OFTEN = {
    "once_a_week" => "About once a week",
    "twice_a_week" => "Twice a week",
    "more" => "More than twice a week"
  }.freeze

  # Old applications have no answers, so these stay optional on them.
  enum :how_often, HOW_OFTEN.keys.index_with(&:itself), prefix: true, validate: { allow_nil: true }
  enum :how_long, PairRequest::COMMITMENTS.keys.index_with(&:itself), prefix: true, validate: { allow_nil: true }

  validates :message, presence: true
  validates :goal, :how_often, :how_long, presence: true, on: :create
  validate :offerer_has_a_level, on: :create
  validates :pair_request_id, uniqueness: { scope: :offerer_id }

  REMIND_AFTER = 24.hours
  ANSWER_WITHIN = 72.hours

  # Signed token for the poster's no-login confirmation link. What the link
  # still allows (accept, already matched, expired) follows the offer's state.
  generates_token_for :poster_confirmation, expires_in: 60.days

  scope :accepted, -> { where.not(accepted_at: nil) }

  def accepted?
    accepted_at?
  end

  def pending?
    status == "PENDING"
  end

  def how_often_label
    HOW_OFTEN[how_often]
  end

  def how_long_label
    PairRequest::COMMITMENTS[how_long]
  end

  # What the application form offers, for its dropdowns.
  def self.form_options
    to_options = ->(labels) { labels.map { |value, label| { value:, label: } } }

    {
      howOften: to_options.call(HOW_OFTEN),
      howLong: to_options.call(PairRequest::COMMITMENTS),
      levels: to_options.call(User::LEVELS.index_with(&:titleize))
    }
  end

  def reminder_at
    created_at + REMIND_AFTER
  end

  def expires_at
    created_at + ANSWER_WITHIN
  end

  def offerer_display_name
    offerer.name.presence || "A Pairin member"
  end

  def expired?
    expires_at <= Time.current
  end

  def status
    if accepted?
      "ACCEPTED"
    elsif pair_request.has_accepted_offer?
      "ACCEPTED OTHER"
    elsif expired?
      "EXPIRED"
    else
      "PENDING"
    end
  end

  private

  # Their level comes from their profile. The form asks once when it's blank.
  def offerer_has_a_level
    errors.add(:level, "can't be blank") unless User::LEVELS.include?(offerer&.level)
  end
end
