class OfferReminderJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  # Scheduled when the offer is created; by the time it runs the offer may
  # have been accepted, matched elsewhere or outlived its slot.
  def perform(offer)
    return unless offer.pending?

    OfferMailer.with(offer:).offer_reminder_email.deliver_later
  end
end
