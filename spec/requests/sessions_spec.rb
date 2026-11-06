require "rails_helper"

RSpec.describe "Workspace sessions", type: :request do
  include ActiveJob::TestHelper

  let(:poster) { create(:user, name: "Maya", timezone: "Europe/Berlin", email: "maya@example.com") }
  let(:partner) { create(:user, name: "Sam", timezone: "Asia/Kolkata", email: "sam@example.com") }
  let(:search) { create(:pair_request, user: poster, subject: "Python buddy") }
  let!(:offer) { create(:offer, pair_request: search, offerer: partner, message: "Hi Maya") }
  let(:partnership) do
    offer.post_message(poster, "Great to meet you")
    offer.propose_partnership!(by: partner)
    offer.accept_proposal!(by: poster)
  end

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  def propose(date: "2030-03-04", time: "18:30", minutes: "60", call_link: "", partnership: self.partnership)
    post partner_sessions_path(partnership), params: { date:, time:, minutes:, call_link: }
  end

  describe "proposing" do
    before do
      partnership
      sign_in(poster)
    end

    it "saves the time in the proposer's timezone, with an optional call link" do
      propose(call_link: "https://meet.google.com/abc-defg-hij")

      expect(response).to redirect_to(partner_sessions_path(partnership))
      session = partnership.sessions.sole
      expect(session).to have_attributes(
        proposed_by: poster,
        start_at: Time.utc(2030, 3, 4, 17, 30),
        end_at: Time.utc(2030, 3, 4, 18, 30),
        call_link: "https://meet.google.com/abc-defg-hij",
        status: "proposed"
      )
    end

    it "lets the other partner propose too, without a call link" do
      sign_in(partner)

      propose

      expect(partnership.sessions.sole).to have_attributes(proposed_by: partner, call_link: nil, start_at: Time.utc(2030, 3, 4, 13, 0))
    end

    it "emails the other partner the time in their own timezone, with a link to the Workspace" do
      perform_enqueued_jobs { propose(call_link: "https://meet.google.com/abc") }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq(["sam@example.com"])
      expect(mail.subject).to eq("Maya proposed a session on Mon 4 Mar")
      body = mail.html_part ? mail.html_part.body.to_s : mail.body.to_s
      expect(body).to include("Monday 4 March", "23:00–00:00", "Asia/Kolkata", "60 minutes", "https://meet.google.com/abc")
      expect(body).to include("/partners/#{partnership.id}/sessions")
    end

    it "signals the other partner" do
      expect { propose }.to have_broadcasted_to(partner).from_channel(ConversationsChannel)
    end

    it "refuses a time in the past" do
      expect { propose(date: Date.yesterday.iso8601) }.not_to change(Session, :count)

      follow_redirect!
      expect(props.dig("errors", "start_at")).to eq("Start must be in the future")
    end

    it "refuses a call link that isn't a web link" do
      expect { propose(call_link: "javascript:alert(1)") }.not_to change(Session, :count)

      follow_redirect!
      expect(props.dig("errors", "call_link")).to eq("Call link must start with http:// or https://")
    end

    it "refuses a length that isn't offered" do
      expect { propose(minutes: "600") }.not_to change(Session, :count)
    end

    it "caps how many proposals one person has waiting" do
      Session::MAX_WAITING.times { |day| propose(date: (Date.current + day + 2).iso8601) }

      expect { propose(date: (Date.current + 30).iso8601) }.not_to change(Session, :count)
      follow_redirect!
      expect(props.dig("errors", "base")).to eq("You already have 5 proposals waiting for an answer.")
    end
  end

  describe "the Sessions page" do
    it "lists upcoming sessions soonest first, then past ones, with both timezones" do
      later = create(:session, partnership:, proposed_by: partner, start_at: 3.days.from_now.change(min: 0), call_link: "https://zoom.us/j/1")
      sooner = create(:session, partnership:, proposed_by: poster, start_at: 1.day.from_now.change(min: 0))
      past = create(:session, partnership:, proposed_by: poster, start_at: 2.days.from_now.change(min: 0))
      past.update_columns(start_at: 2.days.ago, end_at: 2.days.ago + 1.hour)
      sign_in(poster)

      get partner_sessions_path(partnership)

      page = props["partnership"]
      expect(page).to include("timezone" => "Europe/Berlin", "partner_timezone" => "Asia/Kolkata", "lengths" => Session::LENGTHS)
      expect(page.dig("sessions", "upcoming").map { _1["id"] }).to eq([sooner.id, later.id])
      expect(page.dig("sessions", "upcoming").first).to include("mine" => true, "status" => "proposed", "minutes" => 60)
      expect(page.dig("sessions", "upcoming").last).to include("mine" => false, "call_link" => "https://zoom.us/j/1", "start_at" => later.start_at.utc.iso8601)
      expect(page.dig("sessions", "past")).to match([a_hash_including("id" => past.id, "status" => "expired")])
    end

    it "doesn't say where an under-18 partner is" do
      partnership
      partner.update_columns(date_of_birth: 17.years.ago.to_date)
      sign_in(poster)

      get partner_sessions_path(partnership)

      expect(props.dig("partnership", "partner_timezone")).to be_nil
    end
  end

  describe "the overview" do
    it "counts sessions done, confirmed ahead and waiting for an answer, and shows the next confirmed one" do
      done = create(:session, partnership:, proposed_by: partner, status: "confirmed")
      done.update_columns(start_at: 3.days.ago, end_at: 3.days.ago + 1.hour)
      next_one = create(:session, partnership:, proposed_by: partner, status: "confirmed", start_at: 1.day.from_now.change(min: 0), call_link: "https://meet.google.com/x")
      create(:session, partnership:, proposed_by: poster, status: "confirmed", start_at: 4.days.from_now.change(min: 0))
      create(:session, partnership:, proposed_by: partner, start_at: 2.days.from_now.change(min: 0))
      create(:session, partnership:, proposed_by: poster, start_at: 2.days.from_now.change(min: 0))
      create(:session, partnership:, proposed_by: partner, status: "declined", start_at: 2.days.from_now.change(min: 0))
      sign_in(poster)

      get partner_path(partnership)

      expect(props.dig("partnership", "sessions")).to eq(
        "timezone" => "Europe/Berlin",
        "done" => 1,
        "confirmed_ahead" => 2,
        "waiting_on_you" => 1,
        "next" => { "start_at" => next_one.start_at.utc.iso8601, "end_at" => next_one.end_at.utc.iso8601, "call_link" => "https://meet.google.com/x" }
      )
    end

    it "has nothing next when nothing is confirmed" do
      create(:session, partnership:, proposed_by: partner)
      sign_in(poster)

      get partner_path(partnership)

      expect(props.dig("partnership", "sessions")).to include("next" => nil, "waiting_on_you" => 1)
    end
  end

  describe "who can see and propose them" do
    let(:outsider) { create(:user) }

    before do
      create(:session, partnership:, proposed_by: poster)
      sign_in(outsider)
    end

    it "isn't anyone outside the partnership" do
      get partner_sessions_path(partnership)

      expect(response).to have_http_status(:not_found)
    end

    it "doesn't let them propose one" do
      propose

      expect(response).to have_http_status(:not_found)
      expect(partnership.sessions.count).to eq(1)
    end
  end

  it "needs sign-in" do
    get partner_sessions_path(partnership)

    expect(response).to redirect_to(new_user_session_path)
  end

  describe "once the partnership has ended" do
    before do
      create(:session, partnership:, proposed_by: poster)
      partnership.end!(by: partner)
      sign_in(poster)
    end

    it "keeps the sessions readable" do
      get partner_sessions_path(partnership)

      expect(props.dig("partnership", "ended")).to be(true)
      expect(props.dig("partnership", "sessions", "upcoming").size).to eq(1)
    end

    it "doesn't let anyone propose a session" do
      expect { propose }.not_to change(Session, :count)
      expect(flash[:alert]).to eq("This partnership has ended.")
    end
  end
end
