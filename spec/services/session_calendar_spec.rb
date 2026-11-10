require "rails_helper"

RSpec.describe SessionCalendar do
  let(:poster) { create(:user, name: "Maya", email: "maya@example.com") }
  let(:partner) { create(:user, name: "Sam O'Neil", email: "sam@example.com") }
  let(:offer) { create(:offer, pair_request: create(:pair_request, user: poster), offerer: partner) }
  let(:partnership) do
    offer.post_message(poster, "Hi")
    offer.propose_partnership!(by: partner)
    offer.accept_proposal!(by: poster)
  end
  let(:session) do
    create(:session, partnership:, proposed_by: poster, status: "confirmed",
                     start_at: Time.utc(2030, 3, 4, 17, 30), end_at: Time.utc(2030, 3, 4, 19, 0), call_link: "https://meet.google.com/abc-defg-hij")
  end

  def ics(method, for_user: poster)
    described_class.new(session, for_user:).public_send(method)
  end

  # Unfolds continuation lines (RFC 5545 §3.1) and returns name => value.
  def fields(text)
    text.gsub("\r\n ", "").split("\r\n").to_h { |line| line.split(":", 2) }
  end

  describe "the download (PUBLISH)" do
    subject(:file) { ics(:download) }

    it "is a valid calendar with one event, CRLF line endings and lines no longer than 75 octets" do
      expect(file).to start_with("BEGIN:VCALENDAR\r\nVERSION:2.0\r\n")
      expect(file).to end_with("END:VCALENDAR\r\n")
      expect(file.scan("BEGIN:VEVENT").size).to eq(1)
      expect(file.gsub("\r\n", "")).not_to include("\n")
      expect(file.split("\r\n").map(&:bytesize).max).to be <= 75
      expect(fields(file)).to include("METHOD" => "PUBLISH", "PRODID" => "-//Pairin//Sessions//EN")
    end

    it "has the start and end in UTC" do
      expect(fields(file)).to include("DTSTART" => "20300304T173000Z", "DTEND" => "20300304T190000Z")
    end

    it "names the partner from this person's side, with the call link and a link back to the Workspace" do
      workspace = Rails.application.routes.url_helpers.partner_sessions_url(partnership, **Rails.application.config.action_mailer.default_url_options)

      expect(fields(file)).to include(
        "SUMMARY" => "Pairin session with Sam O'Neil",
        "LOCATION" => "https://meet.google.com/abc-defg-hij",
        "URL" => workspace
      )
      expect(fields(file)["DESCRIPTION"]).to include("Call link: https://meet.google.com/abc-defg-hij", "Workspace: #{workspace}")
      expect(fields(ics(:download, for_user: partner))["SUMMARY"]).to eq("Pairin session with Maya")
    end

    it "uses one stable UID per session, so a cancellation finds the same entry" do
      expect(fields(file)["UID"]).to eq("session-#{session.id}@pairin.dev")
      expect(fields(ics(:cancellation))["UID"]).to eq(fields(file)["UID"])
    end

    it "leaves out the call link when there isn't one" do
      session.update_columns(call_link: nil)

      expect(fields(file)).not_to have_key("LOCATION")
      expect(fields(file)["DESCRIPTION"]).not_to include("Call link")
    end

    it "lists neither partner's email address, only Pairin as the organizer, so a later cancellation can match it" do
      expect(file).not_to include("maya@example.com", "sam@example.com", "ATTENDEE")
      expect(file).to include("ORGANIZER;CN=Pairin:mailto:info@pairin.dev")
      expect(fields(file)["SEQUENCE"]).to eq("0")
    end

    it "escapes commas, semicolons, backslashes and newlines in text" do
      partner.update!(name: "Sam; the, \\ coder")
      partner_file = ics(:download)

      expect(fields(partner_file)["SUMMARY"]).to eq("Pairin session with Sam\\; the\\, \\\\ coder")
      # The two description lines are joined by an escaped newline, not a real one.
      expect(fields(partner_file)["DESCRIPTION"]).to match(/Call link: \S+\\nWorkspace: /)
    end

    it "folds long lines without splitting a character, and unfolds back to the original" do
      long_link = "https://meet.google.com/#{'zoë-' * 30}end"
      session.update_columns(call_link: long_link)
      file = ics(:download)

      expect(file.split("\r\n").map(&:bytesize).max).to be <= 75
      expect(file.split("\r\n")).to all(be_valid_encoding)
      expect(fields(file)["LOCATION"]).to eq(long_link)
    end
  end

  describe "the invitation in the confirmation email (REQUEST)" do
    it "is addressed to the recipient only, from Pairin, so mail apps offer to add it" do
      file = ics(:invitation)

      expect(fields(file)).to include("METHOD" => "REQUEST", "STATUS" => "CONFIRMED", "SEQUENCE" => "0")
      expect(file).to include("ORGANIZER;CN=Pairin:mailto:info@pairin.dev")
      # Already agreed, so no Yes/No buttons that would reply to an unread mailbox.
      expect(file.gsub("\r\n ", "")).to include("ATTENDEE;CN=Maya;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;RSVP=FALSE:mailto:maya@example.com")
      expect(file).not_to include("sam@example.com")
    end

    it "quotes a name with commas, colons or semicolons, and drops quotes and control characters" do
      poster.update_columns(name: "Maya \"M\": Lee,\r\nX-INJECTED:1")
      file = ics(:invitation).gsub("\r\n ", "")

      expect(file).to include('ATTENDEE;CN="Maya M: Lee,X-INJECTED:1";ROLE=')
      expect(file.split("\r\n")).not_to include(a_string_starting_with("X-INJECTED"))
    end
  end

  describe "the cancellation (CANCEL)" do
    it "cancels the same entry with a higher sequence" do
      file = ics(:cancellation)

      expect(fields(file)).to include("METHOD" => "CANCEL", "STATUS" => "CANCELLED", "SEQUENCE" => "1",
                                      "UID" => "session-#{session.id}@pairin.dev")
      expect(file).to include("ORGANIZER;CN=Pairin:mailto:info@pairin.dev")
    end
  end

  describe "the Google and Outlook links" do
    def query(url) = Rack::Utils.parse_query(URI(url).query)

    it "opens Google Calendar with the event filled in, named from the viewer's side" do
      url = described_class.new(session, for_user: poster).google_url

      expect(url).to start_with("https://calendar.google.com/calendar/render?")
      expect(query(url)).to include(
        "action" => "TEMPLATE",
        "text" => "Pairin session with Sam O'Neil",
        "dates" => "20300304T173000Z/20300304T190000Z",
        "location" => "https://meet.google.com/abc-defg-hij"
      )
      expect(query(url)["details"]).to include("Call link: https://meet.google.com/abc-defg-hij", "/partners/#{partnership.id}/sessions")
    end

    it "opens Outlook with the event filled in" do
      url = described_class.new(session, for_user: partner).outlook_url

      expect(url).to start_with("https://outlook.live.com/calendar/0/action/compose?")
      expect(query(url)).to include(
        "subject" => "Pairin session with Maya",
        "startdt" => "2030-03-04T17:30:00Z",
        "enddt" => "2030-03-04T19:00:00Z",
        "location" => "https://meet.google.com/abc-defg-hij"
      )
    end

    it "encodes spaces as %20 and escapes characters that would break the link" do
      partner.update_columns(name: "Sam & Co #1")
      url = described_class.new(session, for_user: poster).google_url

      expect(url).not_to include("+", " ")
      expect(query(url)["text"]).to eq("Pairin session with Sam & Co #1")
    end

    it "leaves out the location when there's no call link" do
      session.update_columns(call_link: nil)

      expect(query(described_class.new(session, for_user: poster).google_url)).not_to have_key("location")
      expect(query(described_class.new(session, for_user: poster).outlook_url)).not_to have_key("location")
    end
  end
end
