# Three days after a proposal, once. It's matched on the proposal's time, so a
# proposal declined and made again doesn't get the older one's reminder.
class ProposalReminderJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(offer, proposed_at)
    return unless offer.proposed_at == proposed_at && offer.chat_open? && !offer.partners?

    OfferMailer.with(offer:).proposal_reminder_email.deliver_later
  end
end
