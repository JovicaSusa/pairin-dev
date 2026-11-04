# Two people who agreed to work together on a partner search. Forming one closes
# the rest of the search: it goes Off, and every other application on it ends.
class Partnership < ApplicationRecord
  CLOSING_MESSAGE = "This partner search has found its partner, so this conversation has ended."

  belongs_to :offer
  belongs_to :pair_request

  validates :offer_id, :pair_request_id, uniqueness: true

  after_create :close_the_rest_of_the_search
  after_create_commit :tell_waiting_applicants

  private

  def close_the_rest_of_the_search
    pair_request.switch_off!

    @waiting = []
    pair_request.offers.where.not(id: offer_id).where(ended_at: nil).find_each do |other|
      if other.replied_at?
        other.messages.create!(sender: nil, body: CLOSING_MESSAGE)
      else
        @waiting << other
      end

      other.update_columns(ended_at: Time.current, proposed_at: nil)
    end
  end

  # Anyone already told their application went quiet doesn't hear again.
  def tell_waiting_applicants
    return unless Rails.configuration.x.send_suggestion_emails

    @waiting.reject(&:expiry_notified_at?).each do |waiting|
      OfferMailer.with(offer: waiting).search_filled_email.deliver_later
      waiting.update_columns(expiry_notified_at: Time.current)
    end
  end
end
