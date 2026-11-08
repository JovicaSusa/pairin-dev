# Emails about sessions, always to the partner who didn't act, with the time
# shown in their own timezone.
class SessionMailer < ApplicationMailer
  # What the other partner did, as it reads in a subject line.
  CHANGES = {
    "confirmed" => "confirmed your session",
    "declined" => "declined your session",
    "withdrawn" => "withdrew the session",
    "cancelled" => "cancelled your session"
  }.freeze

  before_action :set_session

  def proposed_email
    @proposer = @session.proposed_by
    recipient = set_times_for(@proposer)

    mail(to: recipient.email, subject: "#{@proposer.display_name} proposed a session on #{@starts.strftime('%a %-d %b')}")
  end

  # `change` is one of CHANGES' keys; `by` is the partner who made it.
  def changed_email
    @by = params[:by]
    @change = params[:change]
    @headline = "#{@by.display_name} #{CHANGES.fetch(@change)}"
    recipient = set_times_for(@by)

    mail(to: recipient.email, subject: "#{@headline} on #{@starts.strftime('%a %-d %b')}")
  end

  private

  def set_session
    @session = params[:session]
  end

  # Returns the other partner, and sets the times in their timezone.
  def set_times_for(actor)
    recipient = @session.partnership.offer.other_person(actor)
    zone = Time.find_zone!(recipient.timezone)
    @starts = @session.start_at.in_time_zone(zone)
    @ends = @session.end_at.in_time_zone(zone)
    @timezone = recipient.timezone
    @sessions_url = partner_sessions_url(@session.partnership)
    recipient
  end
end
