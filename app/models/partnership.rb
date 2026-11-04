# Two people who agreed to work together on a partner search. Forming one closes
# the rest of the search: it goes Off, and every other application on it ends.
class Partnership < ApplicationRecord
  CLOSING_MESSAGE = "This partner search has found its partner, so this conversation has ended."

  belongs_to :offer
  belongs_to :pair_request
  belongs_to :ended_by, class_name: "User", optional: true

  GOAL_MAX_LENGTH = 500

  validates :offer_id, :pair_request_id, uniqueness: true
  validates :goal, length: { maximum: GOAL_MAX_LENGTH }

  normalizes :goal, with: ->(goal) { goal.strip.presence }

  scope :involving, ->(user) {
    joins(:offer, :pair_request).where("offers.offerer_id = :id OR pair_requests.user_id = :id", id: user.id)
  }

  before_create :prefill_goal
  after_create :close_the_rest_of_the_search
  after_create_commit :tell_the_other_applicants

  def ended?
    ended_at? || offer.ended?
  end

  # Ending it ends the chat too, and the search stays Off. The record stays for
  # metrics. The other person hears only that it ended, even after a block, and
  # the reason stays private. Returns false if it had already ended.
  def end!(by:, reason: nil)
    ended = offer.with_lock do
      next false if ended_at?

      update_columns(ended_at: Time.current, ended_by_id: by.id, end_reason: reason.presence)
      offer.not_a_match!(by:)
      true
    end

    OfferMailer.with(offer:, ended_by: by).partnership_ended_email.deliver_later if ended
    ended
  end

  # What each person said they'd commit to: the search's commitment for the
  # poster, and the answer on the application for the applicant.
  def commitment_of(user)
    user == offer.poster ? pair_request.commitment_label : offer.how_long_label
  end

  private

  def prefill_goal
    self.goal = offer.goal.presence&.first(GOAL_MAX_LENGTH) || pair_request.subject.first(GOAL_MAX_LENGTH) if goal.blank?
  end

  # Each offer is re-read under its lock, so a first reply or "Not a match" that
  # lands at the same moment is seen, not overwritten.
  def close_the_rest_of_the_search
    pair_request.switch_off!

    @closed = []
    pair_request.offers.where.not(id: offer_id).where(ended_at: nil).find_each do |other|
      other.with_lock do
        next if other.ended_at?

        other.messages.create!(sender: nil, body: CLOSING_MESSAGE) if other.replied_at?
        other.update_columns(ended_at: Time.current, proposed_at: nil)
        @closed << other
      end
    end
  end

  # Anyone already told their application went quiet doesn't hear again.
  def tell_the_other_applicants
    return unless Rails.configuration.x.send_suggestion_emails

    @closed.reject(&:expiry_notified_at?).each do |closed|
      OfferMailer.with(offer: closed).search_filled_email.deliver_later
      closed.update_columns(expiry_notified_at: Time.current)
    end
  end
end
