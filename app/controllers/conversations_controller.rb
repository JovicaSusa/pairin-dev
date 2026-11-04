# A conversation is an Offer and its messages. Only its two people can open it.
class ConversationsController < ApplicationController
  include Authenticated

  def index
    render_inbox
  end

  def show
    conversation = conversations.find(params[:id])
    conversation.mark_read_by!(current_user)

    render_inbox(conversation)
  end

  def not_a_match
    offer = conversations.find(params[:id])

    if offer.not_a_match!(by: current_user, reason: params[:reason].to_s.first(Message::MAX_LENGTH))
      OfferMailer.with(offer:).not_a_match_email.deliver_later
      ConversationsChannel.notify(offer)
    end

    redirect_to conversation_path(offer)
  end

  def block
    offer = conversations.find(params[:id])
    other = offer.other_person(current_user)

    current_user.block!(other).each { |ended| ConversationsChannel.notify(ended) }

    redirect_to conversation_path(offer), notice: "You've blocked #{other.display_name}. You won't see each other's partner searches."
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

    unread = current_user.unread_message_counts

    render inertia: "Conversations/Index", props: {
      conversations: rows.map { |offer| ConversationPresenter.new(offer, current_user, latest_body: latest_bodies[offer.id], unread: unread.fetch(offer.id, 0)).row },
      conversation: conversation && ConversationPresenter.new(conversation, current_user).thread
    }
  end
end
