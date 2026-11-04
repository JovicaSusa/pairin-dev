# Each person listens only to their own stream, and it only ever carries a
# conversation id. The browser then fetches the update through the normal,
# permission-checked request.
class ConversationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  # Best effort: the page still shows everything on the next load, so a failed
  # signal must never fail the message that caused it.
  def self.notify(offer)
    [offer.offerer, offer.poster].each { |user| broadcast_to(user, { conversation_id: offer.id }) }
  rescue StandardError => e
    Rails.error.report(e, handled: true)
  end
end
