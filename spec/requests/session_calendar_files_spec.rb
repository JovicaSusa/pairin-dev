require "rails_helper"

RSpec.describe "Calendar files for sessions", type: :request do
  include ActiveJob::TestHelper

  let(:poster) { create(:user, name: "Maya", email: "maya@example.com") }
  let(:partner) { create(:user, name: "Sam", email: "sam@example.com") }
  let(:offer) { create(:offer, pair_request: create(:pair_request, user: poster), offerer: partner) }
  let!(:partnership) do
    offer.post_message(poster, "Hi")
    offer.propose_partnership!(by: partner)
    offer.accept_proposal!(by: poster)
  end
  let!(:session) do
    create(:session, partnership:, proposed_by: poster, start_at: Time.utc(2030, 3, 4, 17, 30), end_at: Time.utc(2030, 3, 4, 18, 30), call_link: "https://meet.google.com/x")
  end

  def calendar_part(mail) = mail.attachments.find { _1.mime_type == "text/calendar" }

  describe "the confirmation email" do
    it "carries an invitation for the proposer, so mail apps offer to add it" do
      sign_in(partner)
      perform_enqueued_jobs { patch confirm_partner_session_path(partnership, session) }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq(["maya@example.com"])
      part = calendar_part(mail)
      expect(part.filename).to eq("pairin-session-2030-03-04.ics")
      expect(part.content_type).to include("method=REQUEST")
      body = part.decoded.gsub(/\r?\n /, "") # unfold long lines
      expect(body).to include("METHOD:REQUEST", "DTSTART:20300304T173000Z", "SUMMARY:Pairin session with Sam", "mailto:maya@example.com")
      expect(body).not_to include("sam@example.com")
    end
  end

  describe "the cancellation email" do
    it "carries a cancellation for the same entry" do
      session.update_columns(status: "confirmed", confirmed_at: Time.current)
      sign_in(partner)
      perform_enqueued_jobs { patch cancel_partner_session_path(partnership, session) }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq(["maya@example.com"])
      body = calendar_part(mail).decoded
      expect(body).to include("METHOD:CANCEL", "STATUS:CANCELLED", "UID:session-#{session.id}@pairin.dev")
    end

    it "says to remove an entry added through Google or Outlook, which the file can't reach" do
      session.update_columns(status: "confirmed", confirmed_at: Time.current)
      sign_in(partner)
      perform_enqueued_jobs { patch cancel_partner_session_path(partnership, session) }

      mail = ActionMailer::Base.deliveries.last
      body = mail.html_part ? mail.html_part.body.to_s : mail.body.to_s
      expect(body).to include("If you added it to your calendar, remove it there.")
    end
  end

  it "attaches nothing to the other session emails" do
    sign_in(poster)
    perform_enqueued_jobs { patch withdraw_partner_session_path(partnership, session) }

    expect(calendar_part(ActionMailer::Base.deliveries.last)).to be_nil
  end

  describe "Add to calendar" do
    before { session.update_columns(status: "confirmed", confirmed_at: Time.current) }

    it "downloads the session as a calendar file, named from each person's side" do
      sign_in(partner)

      get calendar_partner_session_path(partnership, session)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/calendar")
      expect(response.headers["Content-Disposition"]).to include("attachment", "pairin-session-2030-03-04.ics")
      expect(response.body).to include("METHOD:PUBLISH", "DTSTART:20300304T173000Z", "SUMMARY:Pairin session with Maya", "LOCATION:https://meet.google.com/x")
      expect(response.body).not_to include("maya@example.com", "sam@example.com", "ATTENDEE")
    end

    it "isn't there for a session that isn't confirmed" do
      session.update_columns(status: "proposed", confirmed_at: nil)
      sign_in(partner)

      get calendar_partner_session_path(partnership, session)

      expect(response).to have_http_status(:not_found)
    end

    it "isn't open to anyone outside the partnership" do
      sign_in(create(:user))

      get calendar_partner_session_path(partnership, session)

      expect(response).to have_http_status(:not_found)
    end

    it "offers Google, Outlook and a download on confirmed upcoming sessions only" do
      past = create(:session, partnership:, proposed_by: poster, status: "confirmed", start_at: 3.days.from_now.change(min: 0))
      past.update_columns(start_at: 2.days.ago, end_at: 2.days.ago + 1.hour)
      sign_in(poster)

      get partner_sessions_path(partnership)

      page = JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]["partnership"]["sessions"]
      links = page["upcoming"].sole["calendar"]
      expect(links["download"]).to eq(calendar_partner_session_path(partnership, session))
      expect(links["google"]).to start_with("https://calendar.google.com/calendar/render?action=TEMPLATE")
      expect(links["outlook"]).to start_with("https://outlook.live.com/calendar/0/action/compose?")
      expect(page["past"].sole["calendar"]).to be_nil
    end
  end
end
