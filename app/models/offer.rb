class Offer < ApplicationRecord
  include ActivityGeneratable

  belongs_to :offerer, class_name: "User"
  belongs_to :pair_request
  belongs_to :period

  validates :message, presence: true
  validates :pair_request_id, uniqueness: { scope: :offerer_id }

  # Signed token for the poster's no-login confirmation link. What the link
  # still allows (accept, already matched, slot passed) follows the offer's state.
  generates_token_for :poster_confirmation, expires_in: 60.days

  scope :future, -> { joins(:period).merge(Period.future) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  def accepted?
    accepted_at?
  end

  def pending?
    status == "PENDING"
  end

  # When to remind the poster: 24h after the offer, or 3h before the slot if
  # that's sooner. Nil when the slot is too close for a reminder to help.
  def reminder_at
    at = [created_at + 24.hours, period.start_at - 3.hours].min

    at if at > Time.current
  end

  def offerer_display_name
    offerer.name.presence || "A Pairin member"
  end

  def expired?
    period.start_at < Time.current
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
