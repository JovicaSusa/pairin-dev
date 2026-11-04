class Conversations::MessagesController < ApplicationController
  include Authenticated

  def create
    offer = Offer.involving(current_user).find(params[:conversation_id])
    late_reply = current_user == offer.poster && offer.overdue?
    message = offer.post_message(current_user, message_params[:body])

    if message.nil?
      redirect_to conversation_path(offer), alert: "You can't write in this conversation right now."
    elsif message.persisted?
      if late_reply
        OfferMailer.with(offer:).late_reply_email.deliver_later
      else
        UnreadMessagesEmailJob.set(wait: Offer::UNREAD_EMAIL_AFTER).perform_later(offer, offer.other_person(current_user))
      end
      redirect_to conversation_path(offer)
    else
      redirect_to conversation_path(offer), inertia: { errors: message.errors.to_hash(true) }
    end
  end

  private

  def message_params = params.require(:message).permit(:body)
end
