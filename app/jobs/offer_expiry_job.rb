# Runs 72 hours after someone applies. An application nobody answered means the
# poster isn't around, so the search is switched off and the poster is asked if
# they're still looking. A reply or a "Not a match" stops this clock.
class OfferExpiryJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(offer)
    return unless offer.unanswered?

    pair_request = offer.pair_request

    # Checked under a row lock on the request.
    paused_now = pair_request.with_lock do
      next false if pair_request.paused? || pair_request.has_accepted_offer?

      pair_request.switch_off!
    end

    return unless paused_now

    PairRequestMailer.with(pair_request:).request_paused_email.deliver_later
    point_offerers_elsewhere(pair_request)
  end

  private

  # Each applicant still waiting hears about a quiet poster once, even if the
  # search is resumed and paused again later. People already talking don't.
  def point_offerers_elsewhere(pair_request)
    return unless Rails.configuration.x.send_suggestion_emails

    not_yet_told = pair_request.offers.where(expiry_notified_at: nil, replied_at: nil, ended_at: nil).to_a
    not_yet_told.each do |offer|
      OfferMailer.with(offer:).offer_expired_email.deliver_later
    end
    Offer.where(id: not_yet_told.map(&:id)).update_all(expiry_notified_at: Time.current)
  end
end
