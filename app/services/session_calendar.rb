# A confirmed session as an iCalendar file (RFC 5545), seen by one partner: it
# names the other one. Three forms of the same event, sharing one UID:
#
# - download:     the "Add to calendar" download, a plain event.
# - invitation:   attached to the confirmation email, as an invitation from Pairin
#   to the recipient, so Gmail, Outlook and Apple Mail offer to add it.
# - cancellation: attached to the cancellation email, so the entry can be removed.
#
# Only the recipient's own address is ever in the file, never the partner's.
class SessionCalendar
  PRODID = "-//Pairin//Sessions//EN".freeze
  MAX_OCTETS = 75

  def initialize(session, for_user:)
    @session = session
    @user = for_user
    @partner = session.partnership.offer.other_person(for_user)
  end

  # Every form has Pairin as the organizer: iTIP requires it on PUBLISH, and it
  # helps a calendar match a later CANCEL to the downloaded entry. A session is
  # never edited in place (a new time is a new session), so the confirmed event
  # is always sequence 0 and its cancellation 1; rescheduling would need a
  # stored revision instead.
  def download = calendar("PUBLISH", sequence: 0)
  def invitation = calendar("REQUEST", status: "CONFIRMED", sequence: 0, attendee: true)
  def cancellation = calendar("CANCEL", status: "CANCELLED", sequence: 1, attendee: true)

  def filename = "pairin-session-#{@session.start_at.getutc.strftime('%Y-%m-%d')}.ics"

  # "Add to calendar" links that open the user's web calendar with the event
  # filled in (#258). Unlike the files they share no UID with us, so a
  # cancellation can't remove what they add.
  def google_url
    link("https://calendar.google.com/calendar/render",
         action: "TEMPLATE", text: title, dates: "#{utc(@session.start_at)}/#{utc(@session.end_at)}",
         details: description, location: @session.call_link)
  end

  # Personal Outlook.com accounts; work and school ones live on outlook.office.com.
  def outlook_url
    link("https://outlook.live.com/calendar/0/action/compose",
         subject: title, startdt: @session.start_at.getutc.iso8601, enddt: @session.end_at.getutc.iso8601,
         body: description, location: @session.call_link)
  end

  private

  def calendar(method, sequence:, status: nil, attendee: false)
    lines = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:#{PRODID}",
      "CALSCALE:GREGORIAN",
      "METHOD:#{method}",
      "BEGIN:VEVENT",
      "UID:session-#{@session.id}@pairin.dev",
      "DTSTAMP:#{utc(Time.current)}",
      "DTSTART:#{utc(@session.start_at)}",
      "DTEND:#{utc(@session.end_at)}",
      "SUMMARY:#{text(title)}",
      ("LOCATION:#{text(@session.call_link)}" if @session.call_link),
      "DESCRIPTION:#{text(description)}",
      "URL:#{workspace_url}",
      ("STATUS:#{status}" if status),
      "SEQUENCE:#{sequence}",
      "ORGANIZER;CN=Pairin:mailto:#{organizer_email}",
      (attendee_line if attendee),
      "END:VEVENT",
      "END:VCALENDAR"
    ].compact

    lines.map { |line| fold(line) }.join("\r\n") + "\r\n"
  end

  def title = "Pairin session with #{@partner.display_name}"

  # Spaces as %20, not +: Outlook shows a + literally.
  def link(base, **params)
    "#{base}?" + params.compact.map { |key, value| "#{key}=#{ERB::Util.url_encode(value)}" }.join("&")
  end

  def description
    [("Call link: #{@session.call_link}" if @session.call_link), "Workspace: #{workspace_url}"].compact.join("\n")
  end

  def workspace_url
    Rails.application.routes.url_helpers.partner_sessions_url(@session.partnership, **Rails.application.config.action_mailer.default_url_options)
  end

  # Only the recipient. Already agreed, so ACCEPTED and RSVP=FALSE: no Yes/No
  # buttons whose replies would go to a mailbox nobody reads.
  def attendee_line
    "ATTENDEE;CN=#{param(@user.display_name)};ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;RSVP=FALSE:mailto:#{@user.email}"
  end

  def organizer_email = Mail::Address.new(ApplicationMailer.default[:from]).address

  def utc(time) = time.getutc.strftime("%Y%m%dT%H%M%SZ")

  # TEXT values: backslash, semicolon, comma and newline are escaped (§3.3.11);
  # other control characters are dropped.
  def text(value)
    value.to_s.gsub("\\", "\\\\\\\\").gsub(";", "\\;").gsub(",", "\\,").gsub(/\r?\n/, "\\n").gsub(/\p{Cntrl}/, "")
  end

  # Parameter values with , ; or : must be quoted, and can't contain quotes or
  # control characters (§3.2), which could otherwise start a new line.
  def param(value)
    value = value.to_s.gsub(/["\p{Cntrl}]/, "")
    value.match?(/[,;:]/) ? %("#{value}") : value
  end

  # Lines longer than 75 octets continue on the next line after CRLF and a
  # space (§3.1), without splitting a multi-byte character.
  def fold(line)
    return line if line.bytesize <= MAX_OCTETS

    parts = [+""]
    line.each_char do |char|
      limit = parts.size == 1 ? MAX_OCTETS : MAX_OCTETS - 1
      parts << +"" if parts.last.bytesize + char.bytesize > limit
      parts.last << char
    end
    parts.join("\r\n ")
  end
end
