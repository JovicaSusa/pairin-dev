# Emails about sessions, always to the partner who didn't act, with the time
# shown in their own timezone.
class SessionMailer < ApplicationMailer
  before_action :set_session

  def proposed_email
    @proposer = @session.proposed_by
    recipient = @session.partnership.offer.other_person(@proposer)
    zone = Time.find_zone!(recipient.timezone)
    @starts = @session.start_at.in_time_zone(zone)
    @ends = @session.end_at.in_time_zone(zone)
    @timezone = recipient.timezone
    @sessions_url = partner_sessions_url(@session.partnership)

    mail(to: recipient.email, subject: "#{@proposer.display_name} proposed a session on #{@starts.strftime('%a %-d %b')}")
  end

  private

  def set_session
    @session = params[:session]
  end
end
