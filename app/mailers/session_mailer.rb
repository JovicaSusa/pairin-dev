# Emails about sessions, always to the partner who didn't act, with the time
# shown in their own timezone. They all share one template, except "Did it
# happen?", which goes to both partners and asks a question.
class SessionMailer < ApplicationMailer
  include Unsubscribable

  before_action :set_session

  def proposed_email
    send_about(
      status: "proposed",
      by: @session.proposed_by,
      heading: "#{@session.proposed_by.display_name} proposed a session",
      next_step: "Open your Workspace to confirm or decline it.",
      show_call_link: true
    )
  end

  def confirmed_email
    send_about(
      status: "confirmed",
      by: params[:by],
      heading: "#{params[:by].display_name} confirmed your session",
      next_step: "It's in your Workspace, with the call link if there is one. The attached invitation adds it to your calendar.",
      show_call_link: true,
      calendar: :invitation
    )
  end

  def declined_email
    send_about(
      status: "declined",
      by: params[:by],
      heading: "#{params[:by].display_name} declined your session",
      next_step: "You can propose another time in your Workspace."
    )
  end

  def withdrawn_email
    send_about(
      status: "withdrawn",
      by: params[:by],
      heading: "#{params[:by].display_name} withdrew a session",
      next_step: "There's nothing to answer any more."
    )
  end

  def cancelled_email
    send_about(
      status: "cancelled",
      by: params[:by],
      # "the", not "your": the other partner may have been the one to propose it.
      heading: "#{params[:by].display_name} cancelled the session",
      next_step: "You can propose another time in your Workspace.",
      calendar: :cancellation
    )
  end

  # An hour before a confirmed session, to each partner (#231). No unsubscribe:
  # both agreed to the session. Sends nothing if it has been cancelled since.
  def reminder_email
    partner = @session.partnership.offer.other_person(params[:recipient])

    send_about(
      status: "confirmed",
      # send_about emails the other person of `by`, so passing the partner
      # sends it to the recipient.
      by: partner,
      # Not "in an hour": after a job outage it can go out later than that.
      heading: "Your session with #{partner.display_name} is coming up",
      next_step: "Join from the call link, or open your Workspace to see the details.",
      show_call_link: true,
      subject: ->(starts) { "Reminder: your session with #{partner.display_name} at #{starts.strftime('%H:%M')}" }
    )
  end

  # After a confirmed session ends, to each partner, with one-click Yes and No
  # links that work without signing in. Optional, like the weekly check-in.
  def did_it_happen_email
    answer = params[:answer]
    user = answer.user
    @partner = @session.partnership.offer.other_person(user)
    zone = Time.find_zone!(user.timezone)
    @starts = @session.start_at.in_time_zone(zone)
    @ends = @session.end_at.in_time_zone(zone)
    @timezone = user.timezone
    token = answer.generate_token_for(:answer)
    @yes_url = session_answer_url(token:, answer: "yes")
    @no_url = session_answer_url(token:, answer: "no")

    allow_unsubscribe(user, "suggestions")

    mail(to: user.email, subject: "Did your session with #{@partner.display_name} happen?")
  end

  private

  def set_session
    @session = params[:session]
  end

  # Sends nothing if the session has moved on since: the job loads it fresh,
  # and an email about a confirmation that was then cancelled (or whose
  # partnership ended) would describe a session that isn't happening.
  # `subject`, if given, builds the subject from the start time in the
  # recipient's timezone; otherwise it's the heading and the day. `calendar`
  # attaches the session as an :invitation or a :cancellation for the
  # recipient (#230).
  def send_about(status:, by:, heading:, next_step:, show_call_link: false, subject: nil, calendar: nil)
    return unless @session.status == status

    recipient = @session.partnership.offer.other_person(by)
    zone = Time.find_zone!(recipient.timezone)
    @starts = @session.start_at.in_time_zone(zone)
    @ends = @session.end_at.in_time_zone(zone)
    @timezone = recipient.timezone
    @heading = heading
    @next_step = next_step
    @show_call_link = show_call_link
    @sessions_url = partner_sessions_url(@session.partnership)

    attach_calendar(calendar, recipient) if calendar

    subject = subject ? subject.call(@starts) : "#{heading} on #{@starts.strftime('%a %-d %b')}"
    mail(to: recipient.email, subject:, template_name: "session_email")
  end

  # The method parameter on the content type is what makes Gmail, Outlook and
  # Apple Mail treat it as an invitation (or its cancellation).
  def attach_calendar(kind, recipient)
    file = SessionCalendar.new(@session, for_user: recipient)
    method = kind == :cancellation ? "CANCEL" : "REQUEST"

    attachments[file.filename] = {
      content_type: "text/calendar; method=#{method}; charset=UTF-8",
      content: file.public_send(kind)
    }
  end
end
