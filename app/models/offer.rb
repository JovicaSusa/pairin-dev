class Offer < ApplicationRecord
  include ActivityGeneratable

  belongs_to :offerer, class_name: "User"
  belongs_to :pair_request
  # History only: applications used to book a time. New ones have no period.
  has_one :period, as: :periodable, dependent: :destroy, inverse_of: :periodable, autosave: true

  validates :message, presence: true
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
end
