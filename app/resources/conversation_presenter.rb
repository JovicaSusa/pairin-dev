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
      other: { name: @other.display_name, image_url: @other.image_url }
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
      search: { subject: @offer.pair_request.subject, commitment_label: @offer.pair_request.commitment_label },
      application: application,
      other: {
        name: @other.display_name,
        image_url: @other.image_url,
        level: @other.level_titleized,
        github_url: @other.github_url
      },
      messages: @offer.messages.order(:created_at, :id).map { |message|
        { id: message.id, mine: message.sender_id == @viewer.id, body: message.body, at: message.created_at.utc.iso8601 }
      }
    }
  end

  private

  def status
    @offer.conversation_status_for(@viewer)
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
