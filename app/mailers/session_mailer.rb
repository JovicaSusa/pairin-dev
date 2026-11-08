# Emails about sessions, always to the partner who didn't act, with the time
# shown in their own timezone. They all share one template.
class SessionMailer < ApplicationMailer
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
      next_step: "It's in your Workspace, with the call link if there is one.",
      show_call_link: true
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
      next_step: "You can propose another time in your Workspace."
    )
  end

  private

  def set_session
    @session = params[:session]
  end

  # Sends nothing if the session has moved on since: the job loads it fresh,
  # and an email about a confirmation that was then cancelled (or whose
  # partnership ended) would describe a session that isn't happening.
  def send_about(status:, by:, heading:, next_step:, show_call_link: false)
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

    mail(to: recipient.email, subject: "#{heading} on #{@starts.strftime('%a %-d %b')}", template_name: "session_email")
  end
end
