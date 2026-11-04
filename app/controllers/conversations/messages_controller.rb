class Conversations::MessagesController < ApplicationController
  include Authenticated

  def create
    offer = Offer.involving(current_user).find(params[:conversation_id])
    message = offer.post_message(current_user, message_params[:body])

    if message.nil?
      redirect_to conversation_path(offer), alert: "You can't write in this conversation right now."
    elsif message.persisted?
      redirect_to conversation_path(offer)
    else
      redirect_to conversation_path(offer), inertia: { errors: message.errors.to_hash(true) }
    end
  end

  private

  def message_params = params.require(:message).permit(:body)
end
