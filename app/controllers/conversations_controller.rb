# A conversation is an Offer and its messages. Only its two people can open it.
class ConversationsController < ApplicationController
  include Authenticated

  def index
    render_inbox
  end

  def show
    render_inbox(conversations.find(params[:id]))
  end

  def not_a_match
    offer = conversations.find(params[:id])

    if offer.not_a_match!(by: current_user, reason: params[:reason].to_s.first(Message::MAX_LENGTH))
      OfferMailer.with(offer:).not_a_match_email.deliver_later
    end

    redirect_to conversation_path(offer)
  end

  private

  def conversations
    Offer.involving(current_user)
  end

  def render_inbox(conversation = nil)
    rows = conversations
      .includes(:offerer, pair_request: :user)
      .order(last_message_at: :desc, id: :desc)
      .to_a
    latest_bodies = Message
      .where(offer_id: rows.map(&:id))
      .select("DISTINCT ON (offer_id) offer_id, body")
      .order(:offer_id, created_at: :desc, id: :desc)
      .to_h { |message| [message.offer_id, message.body] }

    render inertia: "Conversations/Index", props: {
      conversations: rows.map { |offer| ConversationPresenter.new(offer, current_user, latest_body: latest_bodies[offer.id]).row },
      conversation: conversation && ConversationPresenter.new(conversation, current_user).thread
    }
  end
end
