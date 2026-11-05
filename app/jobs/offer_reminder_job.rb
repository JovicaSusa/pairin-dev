class OfferReminderJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  # Scheduled when someone applies. By then the poster may have replied, or
  # either person may have ended the conversation.
  def perform(offer)
    return unless offer.unanswered?
    return if offer.pair_request.has_accepted_offer?
    return if offer.pair_request.paused?

    OfferMailer.with(offer:).offer_reminder_email.deliver_later
  end
end
