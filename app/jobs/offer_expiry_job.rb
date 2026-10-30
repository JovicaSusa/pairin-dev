# Runs when an offer's slot starts. An offer nobody answered means the poster
# isn't around, so the request is switched off and the poster is asked if
# they're still looking.
class OfferExpiryJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(offer)
    pair_request = offer.pair_request
    return if pair_request.has_accepted_offer?

    paused_now = pair_request.with_lock do
      next false if pair_request.paused?

      pair_request.switch_off!
    end

    PairRequestMailer.with(pair_request:).request_paused_email.deliver_later if paused_now
  end
end
