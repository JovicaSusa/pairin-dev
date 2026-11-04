# What one person sees of a conversation (an Offer and its messages).
class ConversationPresenter
  LINE_LENGTH = 60

  def initialize(offer, viewer, latest_body: nil, unread: 0)
    @offer = offer
    @viewer = viewer
    @latest_body = latest_body
    @unread = unread
    @other = offer.other_person(viewer)
  end

  def row
    {
      id: @offer.id,
      status: status,
      line: line,
      unread: @unread,
      other: other_profile.slice(:name, :image_url)
    }
  end

  def thread
    {
      id: @offer.id,
      status: status,
      viewer_is_poster: @viewer == @offer.poster,
      chat_open: @offer.chat_open?,
      ended: @offer.ended?,
      ended_by_viewer: @offer.ended_by_id == @viewer.id,
      can_send: @offer.can_message?(@viewer),
      partners: @offer.partners?,
      can_propose: @offer.can_propose?,
      proposal: proposal,
      search: { subject: @offer.pair_request.subject, commitment_label: @offer.pair_request.commitment_label },
      application: application,
      other: other_profile.slice(:name, :image_url, :level, :github_url),
      messages: @offer.messages.order(:created_at, :id).map { |message|
        { id: message.id, mine: message.sender_id == @viewer.id, body: message.body, at: message.created_at.utc.iso8601 }
      }
    }
  end

  private

  def other_profile
    @other_profile ||= @other.profile_for_others
  end

  def status
    @offer.conversation_status_for(@viewer)
  end

  # Each person sees their own side of it. A "not yet" only shows to the person
  # who proposed, until someone proposes again.
  def proposal
    return unless @offer.chat_open?
    return "waiting" if @offer.proposal_pending? && @offer.proposed_by_id == @viewer.id
    return "incoming" if @offer.proposal_pending?

    "declined" if @offer.proposal_declined_at? && @offer.proposed_by_id == @viewer.id && !@offer.partners?
  end

  def application
    return if @offer.goal.blank?

    { goal: @offer.goal, how_often_label: @offer.how_often_label, how_long_label: @offer.how_long_label }
  end

  def line
    case status
    when "Ended" then "Conversation ended"
    when "Sent" then "Waiting for #{@other.display_name} to reply"
    when "Reply" then "New application"
    else @latest_body.to_s.truncate(LINE_LENGTH)
    end
  end
end
