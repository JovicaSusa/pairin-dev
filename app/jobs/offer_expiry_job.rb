# Runs when an offer's slot starts. An offer nobody answered means the poster
# isn't around, so the request is switched off and the poster is asked if
# they're still looking.
class OfferExpiryJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(offer)
    pair_request = offer.pair_request

    # Checked under the same row lock Offers::Accept takes, so an accept that
    # commits just before this can't be followed by a pause.
    paused_now = pair_request.with_lock do
      next false if pair_request.paused? || pair_request.has_accepted_offer?

      pair_request.switch_off!
    end

    return unless paused_now

    PairRequestMailer.with(pair_request:).request_paused_email.deliver_later
    point_offerers_elsewhere(pair_request)
  end

  private

  # Each offerer hears about a quiet poster once, even if the request is
  # resumed and paused again later.
  def point_offerers_elsewhere(pair_request)
    return unless Rails.configuration.x.send_suggestion_emails

    not_yet_told = pair_request.offers.where(expiry_notified_at: nil).to_a
    not_yet_told.each do |offer|
      OfferMailer.with(offer:).offer_expired_email.deliver_later
    end
    Offer.where(id: not_yet_told.map(&:id)).update_all(expiry_notified_at: Time.current)
  end
end
