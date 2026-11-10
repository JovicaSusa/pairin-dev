# A Workspace's Sessions page: either partner proposes a time, the other
# confirms or declines it, and either can cancel a confirmed one. Both see every
# session, each in their own timezone, and each change emails the other.
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
          past: sessions.past.includes(:answers).map { |session| props_for(session, past: true) }
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

  def confirm
    change(:confirm!, :confirmed_email)
  end

  def decline
    change(:decline!, :declined_email)
  end

  def withdraw
    change(:withdraw!, :withdrawn_email)
  end

  def cancel
    change(:cancel!, :cancelled_email)
  end

  # "Add to calendar": the session as an .ics file, named from the viewer's
  # side (#230). Only for confirmed sessions.
  def calendar
    planned = @partnership.sessions.confirmed.find(params[:id])
    file = SessionCalendar.new(planned, for_user: current_user)

    send_data file.download, filename: file.filename, type: "text/calendar; charset=utf-8", disposition: "attachment"
  end

  private

  # Says so, rather than erroring, when the other partner got there first or
  # the session has started.
  # (`planned`, not `session`, which would hide Rails' own session here.)
  def change(transition, email)
    planned = @partnership.sessions.find(params[:id])

    if planned.public_send(transition, by: current_user)
      SessionMailer.with(session: planned, by: current_user).public_send(email).deliver_later
      ConversationsChannel.notify(@partnership.offer)
      redirect_back_or_to partner_sessions_path(@partnership)
    else
      # Same wording as proposing in an ended partnership, when that's the reason.
      alert = @partnership.reload.ended? ? "This partnership has ended." : "This session can't be changed any more."
      redirect_back_or_to partner_sessions_path(@partnership), alert:
    end
  end

  def set_partnership
    @partnership = partnerships.find(params[:partner_id])
  end

  # "Add to calendar": Google, Outlook, or the .ics file for anything else (#258).
  def calendar_links(session)
    file = SessionCalendar.new(session, for_user: current_user)
    { google: file.google_url, outlook: file.outlook_url, download: calendar_partner_session_path(@partnership, session) }
  end

  # Only past sessions have "Did it happen?" answers; the past list preloads them.
  def props_for(session, past: false)
    happened = session.happened if past

    {
      id: session.id,
      start_at: session.start_at.utc.iso8601,
      end_at: session.end_at.utc.iso8601,
      minutes: session.minutes,
      call_link: session.call_link,
      status: session.expired? ? "expired" : session.status,
      mine: session.proposed_by_id == current_user.id,
      cancelled_by: session.cancelled_by_id && (session.cancelled_by_id == current_user.id ? "you" : "partner"),
      calendar: (calendar_links(session) if session.confirmed? && !past),
      # "Did it happen?": true, false, or nil until either partner answers.
      happened: (happened if session.confirmed?),
      ended: session.end_at.past?,
      can: {
        answer: session.answerable_by?(current_user),
        withdraw: session.withdrawable_by?(current_user),
        cancel: session.cancellable_by?(current_user)
      }
    }
  end
end
