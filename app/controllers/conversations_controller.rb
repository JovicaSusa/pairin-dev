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

    return redirect_to conversation_path(offer), alert: "You're partners now, so this can't be undone from here." if offer.partners?

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

    back_to_thread(offer, notice: "You've blocked #{other.display_name}. You won't see each other's partner searches.")
  end

  def report
    offer = conversations.find(params[:id])
    reason = params[:reason].to_s.strip.first(Message::MAX_LENGTH)

    if reason.empty?
      back_to_thread(offer, inertia: { errors: { reason: "Please say what happened" } })
    else
      ReportMailer.with(offer:, reporter: current_user, reason:).chat_report.deliver_later
      back_to_thread(offer, notice: "Thanks for telling us. We'll look into it.")
    end
  end

  def propose
    offer = conversations.find(params[:id])

    case offer.propose_partnership!(by: current_user)
    when :proposed
      OfferMailer.with(offer:).proposal_email.deliver_later
      ProposalReminderJob.set(wait: Offer::PROPOSAL_REMINDER_AFTER).perform_later(offer, offer.proposed_at)
    when :accepted
      announce_partnership(offer)
      ConversationsChannel.notify(offer)
      return redirect_to partner_path(offer.partnership)
    end

    ConversationsChannel.notify(offer)
    redirect_to conversation_path(offer)
  end

  def accept_proposal
    offer = conversations.find(params[:id])
    proposer = offer.proposed_by

    unless offer.accept_proposal!(by: current_user)
      return redirect_to conversation_path(offer), alert: "This proposal isn't open any more."
    end

    announce_partnership(offer, proposer)
    ConversationsChannel.notify(offer)
    redirect_to partner_path(offer.reload.partnership)
  end

  def decline_proposal
    offer = conversations.find(params[:id])

    ConversationsChannel.notify(offer) if offer.decline_proposal!(by: current_user)

    redirect_to conversation_path(offer)
  end

  private

  def back_to_thread(offer, **options)
    redirect_back_or_to conversation_path(offer), allow_other_host: false, **options
  end

  # Whoever accepted is here to see it. The proposer may not be.
  def announce_partnership(offer, proposer = offer.other_person(current_user))
    OfferMailer.with(offer:, recipient: proposer).proposal_accepted_email.deliver_later
  end

  def conversations
    Offer.involving(current_user)
  end

  def render_inbox(conversation = nil)
    rows = conversations
      .includes(:offerer, :partnership, pair_request: :user)
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
