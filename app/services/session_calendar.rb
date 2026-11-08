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
  include Rails.application.routes.url_helpers

  PRODID = "-//Pairin//Sessions//EN".freeze
  MAX_OCTETS = 75

  def initialize(session, for_user:)
    @session = session
    @user = for_user
    @partner = session.partnership.offer.other_person(for_user)
  end

  def download = calendar("PUBLISH")
  def invitation = calendar("REQUEST", status: "CONFIRMED", sequence: 0, addressed: true)
  def cancellation = calendar("CANCEL", status: "CANCELLED", sequence: 1, addressed: true)

  def filename = "pairin-session-#{@session.start_at.utc.strftime('%Y-%m-%d')}.ics"

  private

  def default_url_options = Rails.application.config.action_mailer.default_url_options

  def calendar(method, status: nil, sequence: nil, addressed: false)
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
      "SUMMARY:#{text("Pairin session with #{@partner.display_name}")}",
      ("LOCATION:#{text(@session.call_link)}" if @session.call_link),
      "DESCRIPTION:#{text(description)}",
      "URL:#{workspace_url}",
      ("STATUS:#{status}" if status),
      ("SEQUENCE:#{sequence}" if sequence),
      *(addressed ? addresses : []),
      "END:VEVENT",
      "END:VCALENDAR"
    ].compact

    lines.map { |line| fold(line) }.join("\r\n") + "\r\n"
  end

  def description
    [("Call link: #{@session.call_link}" if @session.call_link), "Workspace: #{workspace_url}"].compact.join("\n")
  end

  def workspace_url = partner_sessions_url(@session.partnership)

  def addresses
    [
      "ORGANIZER;CN=Pairin:mailto:#{organizer_email}",
      "ATTENDEE;CN=#{param(@user.display_name)};ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED:mailto:#{@user.email}"
    ]
  end

  def organizer_email = Mail::Address.new(ApplicationMailer.default[:from]).address

  def utc(time) = time.utc.strftime("%Y%m%dT%H%M%SZ")

  # TEXT values: backslash, semicolon, comma and newline are escaped (§3.3.11).
  def text(value)
    value.to_s.gsub("\\", "\\\\\\\\").gsub(";", "\\;").gsub(",", "\\,").gsub(/\r?\n/, "\\n")
  end

  # Parameter values with , ; or : must be quoted, and can't contain quotes (§3.2).
  def param(value)
    value = value.to_s.delete('"')
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
