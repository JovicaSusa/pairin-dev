# A Workspace: the page two partners share. Only those two can open it.
class PartnershipsController < ApplicationController
  include Authenticated
  include WorkspacePages

  LAST_MESSAGE_LENGTH = 140

  def index
    partnerships = Partnership.involving(current_user)
      .includes(:pair_request, offer: :offerer, pair_request: :user)
      .order(Arel.sql("partnerships.ended_at IS NOT NULL"), created_at: :desc)

    render inertia: "Partners/Index", props: {
      partnerships: partnerships.map { |partnership|
        partner = partnership.offer.other_person(current_user).profile_for_others

        {
          id: partnership.id,
          goal: partnership.goal,
          subject: partnership.pair_request.subject,
          ended: partnership.ended?,
          partner: partner.slice(:name, :image_url)
        }
      }
    }
  end

  # The overview. It doesn't mark the chat read, so the Chat tile can say
  # what's new.
  def show
    partnership = partnerships.includes(:check_ins).find(params[:id])
    offer = partnership.offer
    last_message = offer.messages.where.not(sender_id: nil).order(:created_at, :id).last

    render inertia: "Partners/Show", props: {
      partnership: workspace(partnership).merge(
        weeks: partnership.weeks_summary,
        next_check_in_at: partnership.next_check_in_at.utc.iso8601,
        your_commitment: partnership.commitment_of(current_user),
        partner_commitment: partnership.commitment_of(offer.other_person(current_user)),
        unread: offer.unread_messages_for(current_user).count,
        sessions: sessions_summary(partnership),
        resources: resources_summary(partnership),
        last_message: last_message && {
          body: last_message.body.truncate(LAST_MESSAGE_LENGTH),
          mine: last_message.sender_id == current_user.id
        }
      )
    }
  end

  def chat
    partnership = partnerships.find(params[:id])
    partnership.offer.mark_read_by!(current_user)

    render inertia: "Partners/Chat", props: {
      partnership: workspace(partnership).merge(
        conversation: ConversationPresenter.new(partnership.offer, current_user).thread
      )
    }
  end

  def update
    partnership = partnerships.find(params[:id])

    if partnership.ended?
      redirect_to partner_path(partnership), alert: "This partnership has ended."
    elsif partnership.update(goal: params.fetch(:goal, partnership.goal).to_s)
      ConversationsChannel.notify(partnership.offer)
      redirect_to partner_path(partnership)
    else
      redirect_to partner_path(partnership), inertia: { errors: partnership.errors.to_hash(true) }
    end
  end

  def end_partnership
    partnership = partnerships.find(params[:id])

    if partnership.end!(by: current_user, reason: params[:reason].to_s.strip.first(Message::MAX_LENGTH))
      ConversationsChannel.notify(partnership.offer)
    end

    redirect_to partner_path(partnership)
  end

  private

  def sessions_summary(partnership)
    sessions = partnership.sessions
    upcoming = sessions.where(start_at: Time.current..)
    next_session = upcoming.confirmed.order(:start_at, :id).first

    {
      timezone: current_user.timezone,
      # Took place: a partner said Yes to "Did it happen?" (#232).
      done: sessions.completed.count,
      confirmed_ahead: upcoming.confirmed.count,
      waiting_on_you: upcoming.proposed.where.not(proposed_by: current_user).count,
      next: next_session && {
        start_at: next_session.start_at.utc.iso8601,
        end_at: next_session.end_at.utc.iso8601,
        call_link: next_session.call_link
      }
    }
  end

  def resources_summary(partnership)
    links = partnership.shared_links
    latest = links.order(:created_at, :id).last

    { count: links.count, latest: latest&.host }
  end
end
