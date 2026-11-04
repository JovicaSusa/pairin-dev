# Scheduled for each chat message, so it runs about 15 minutes later. Whichever
# job finds unread messages old enough sends the one email, and the rest find
# there's nothing to do.
class UnreadMessagesEmailJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(offer, recipient)
    due = offer.with_lock do
      next false unless offer.unread_email_due_for?(recipient)

      offer.mark_unread_emailed_to!(recipient)
      true
    end

    OfferMailer.with(offer:, recipient:).unread_messages_email.deliver_later if due
  end
end
