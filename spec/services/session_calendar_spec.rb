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
      workspace = "http://localhost:3000/partners/#{partnership.id}/sessions"

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

    it "lists nobody's email address" do
      expect(file).not_to include("maya@example.com", "sam@example.com", "ATTENDEE", "ORGANIZER")
    end

    it "escapes commas, semicolons, backslashes and newlines in text" do
      partner.update!(name: "Sam; the, \\ coder")
      partner_file = ics(:download)

      expect(fields(partner_file)["SUMMARY"]).to eq("Pairin session with Sam\\; the\\, \\\\ coder")
    end
  end

  describe "the invitation in the confirmation email (REQUEST)" do
    it "is addressed to the recipient only, from Pairin, so mail apps offer to add it" do
      file = ics(:invitation)

      expect(fields(file)).to include("METHOD" => "REQUEST", "STATUS" => "CONFIRMED", "SEQUENCE" => "0")
      expect(file).to include("ORGANIZER;CN=Pairin:mailto:info@pairin.dev")
      expect(file.gsub("\r\n ", "")).to include("ATTENDEE;CN=Maya;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED:mailto:maya@example.com")
      expect(file).not_to include("sam@example.com")
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
end
