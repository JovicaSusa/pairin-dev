# A Workspace's Sessions page: either partner proposes a time, and both see
# every session, each in their own timezone. Answering comes with #229.
class Partners::SessionsController < ApplicationController
  include Authenticated
  include WorkspacePages

  before_action :set_partnership

  def index
    sessions = @partnership.sessions
    partner = @partnership.offer.other_person(current_user)

    render inertia: "Partners/Sessions", props: {
      partnership: workspace(@partnership).merge(
        timezone: current_user.timezone,
        # A minor's partner sees only their name, so not where they are either.
        partner_timezone: (partner.timezone unless partner.minor?),
        lengths: Session::LENGTHS,
        sessions: {
          upcoming: sessions.upcoming.map { |session| props_for(session) },
          past: sessions.past.map { |session| props_for(session) }
        }
      )
    }
  end

  def create
    if @partnership.ended?
      return redirect_to partner_sessions_path(@partnership), alert: "This partnership has ended."
    end

    session = Session.propose(
      partnership: @partnership,
      by: current_user,
      date: params[:date],
      time: params[:time],
      minutes: params[:minutes],
      call_link: params[:call_link].to_s
    )

    if session.save
      SessionMailer.with(session:).proposed_email.deliver_later
      ConversationsChannel.notify(@partnership.offer)
      redirect_to partner_sessions_path(@partnership)
    else
      redirect_to partner_sessions_path(@partnership), inertia: { errors: session.errors.to_hash(true).transform_values(&:first) }
    end
  end

  private

  def set_partnership
    @partnership = partnerships.find(params[:partner_id])
  end

  def props_for(session)
    {
      id: session.id,
      start_at: session.start_at.utc.iso8601,
      end_at: session.end_at.utc.iso8601,
      minutes: session.minutes,
      call_link: session.call_link,
      status: session.expired? ? "expired" : session.status,
      mine: session.proposed_by_id == current_user.id
    }
  end
end
