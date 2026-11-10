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

    it "lists upcoming declined, withdrawn and cancelled sessions under Not happening, soonest first" do
      confirmed = create(:session, partnership:, proposed_by: partner, start_at: 4.days.from_now.change(min: 0))
      confirmed.confirm!(by: poster)
      proposed = create(:session, partnership:, proposed_by: partner, start_at: 5.days.from_now.change(min: 0))
      cancelled = create(:session, partnership:, proposed_by: partner, start_at: 1.day.from_now.change(min: 0))
      cancelled.confirm!(by: poster)
      cancelled.cancel!(by: poster)
      declined = create(:session, partnership:, proposed_by: partner, start_at: 3.days.from_now.change(min: 0))
      declined.decline!(by: poster)
      withdrawn = create(:session, partnership:, proposed_by: poster, start_at: 2.days.from_now.change(min: 0))
      withdrawn.withdraw!(by: poster)
      gone = create(:session, partnership:, proposed_by: partner, start_at: 2.days.from_now.change(min: 0))
      gone.decline!(by: poster)
      gone.update_columns(start_at: 2.days.ago, end_at: 2.days.ago + 1.hour)
      sign_in(poster)

      get partner_sessions_path(partnership)

      sessions = props.dig("partnership", "sessions")
      expect(sessions["upcoming"].map { _1["id"] }).to eq([confirmed.id, proposed.id])
      expect(sessions["not_happening"].map { _1["id"] }).to eq([cancelled.id, withdrawn.id, declined.id])
      expect(sessions["past"].map { _1["id"] }).to eq([gone.id])
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
      # "Done together" counts only sessions that took place: a partner said
      # Yes to "Did it happen?". Not ones both said didn't, nor unanswered ones.
      past = ->(days_ago) { create(:session, partnership:, proposed_by: partner, status: "confirmed").tap { _1.update_columns(start_at: days_ago.days.ago, end_at: days_ago.days.ago + 1.hour) } }
      took_place = past.(3)
      took_place.answers.create!(user: poster).answer!(true)
      didnt_happen = past.(4)
      didnt_happen.answers.create!(user: poster).answer!(false)
      past.(5) # nobody answered
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
      expect(props.dig("partnership", "sessions", "not_happening").size).to eq(1)
    end

    it "doesn't let anyone propose a session" do
      expect { propose }.not_to change(Session, :count)
      expect(flash[:alert]).to eq("This partnership has ended.")
    end
  end

  describe "answering and cancelling" do
    let!(:session) { create(:session, partnership:, proposed_by: poster, start_at: Time.utc(2030, 3, 4, 17, 30), end_at: Time.utc(2030, 3, 4, 18, 30), call_link: "https://meet.google.com/x") }

    def mail_body(mail)
      mail.html_part ? mail.html_part.body.to_s : mail.body.to_s
    end

    it "doesn't send an email about a change that has since been undone" do
      sign_in(partner)
      patch confirm_partner_session_path(partnership, session)
      patch cancel_partner_session_path(partnership, session)

      perform_enqueued_jobs

      # The confirmation (with its call link) would describe a session that's
      # now cancelled, so only the cancellation goes out.
      expect(ActionMailer::Base.deliveries.map(&:subject)).to eq(["Sam cancelled the session on Mon 4 Mar"])
    end

    it "doesn't send a confirmation once the partnership has ended" do
      sign_in(partner)
      patch confirm_partner_session_path(partnership, session)
      partnership.end!(by: poster)

      perform_enqueued_jobs

      expect(ActionMailer::Base.deliveries.map(&:subject)).not_to include(a_string_including("confirmed"))
    end

    it "lets the partner confirm, emails the proposer the time in their timezone, and signals them" do
      sign_in(partner)

      expect { patch confirm_partner_session_path(partnership, session) }.to have_broadcasted_to(poster).from_channel(ConversationsChannel)

      expect(response).to redirect_to(partner_sessions_path(partnership))
      expect(session.reload).to be_confirmed
      perform_enqueued_jobs
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq(["maya@example.com"])
      expect(mail.subject).to eq("Sam confirmed your session on Mon 4 Mar")
      expect(mail_body(mail)).to include("18:30–19:30", "Europe/Berlin", "https://meet.google.com/x")
    end

    it "lets the partner decline, and emails the proposer" do
      sign_in(partner)

      perform_enqueued_jobs { patch decline_partner_session_path(partnership, session) }

      expect(session.reload).to be_declined
      expect(ActionMailer::Base.deliveries.last).to have_attributes(to: ["maya@example.com"], subject: "Sam declined your session on Mon 4 Mar")
    end

    it "lets the proposer withdraw, and emails the partner" do
      sign_in(poster)

      perform_enqueued_jobs { patch withdraw_partner_session_path(partnership, session) }

      expect(session.reload).to be_withdrawn
      expect(ActionMailer::Base.deliveries.last).to have_attributes(to: ["sam@example.com"], subject: "Maya withdrew a session on Mon 4 Mar")
    end

    it "lets either partner cancel a confirmed session, and emails the other" do
      session.confirm!(by: partner)
      sign_in(poster)

      perform_enqueued_jobs { patch cancel_partner_session_path(partnership, session) }

      expect(session.reload).to have_attributes(status: "cancelled", cancelled_by: poster)
      mail = ActionMailer::Base.deliveries.last
      expect(mail).to have_attributes(to: ["sam@example.com"], subject: "Maya cancelled the session on Mon 4 Mar")
      expect(mail_body(mail)).not_to include("https://meet.google.com/x")
    end

    it "doesn't let the proposer answer their own proposal" do
      sign_in(poster)

      expect { patch confirm_partner_session_path(partnership, session) }.not_to have_enqueued_mail(SessionMailer)

      expect(session.reload).to be_proposed
      expect(flash[:alert]).to eq("This session can't be changed any more.")
    end

    it "says so when the session was already answered" do
      session.decline!(by: partner)
      sign_in(partner)

      patch confirm_partner_session_path(partnership, session)

      expect(session.reload).to be_declined
      expect(flash[:alert]).to eq("This session can't be changed any more.")
    end

    it "shows each person what they can do, and who cancelled" do
      sign_in(partner)
      get partner_sessions_path(partnership)
      expect(props.dig("partnership", "sessions", "upcoming", 0, "can")).to eq("answer" => true, "withdraw" => false, "cancel" => false)

      sign_in(poster)
      get partner_sessions_path(partnership)
      expect(props.dig("partnership", "sessions", "upcoming", 0, "can")).to eq("answer" => false, "withdraw" => true, "cancel" => false)

      session.confirm!(by: partner)
      session.cancel!(by: partner)
      get partner_sessions_path(partnership)
      expect(props.dig("partnership", "sessions", "not_happening", 0)).to include("status" => "cancelled", "cancelled_by" => "partner")
    end

    %i[confirm decline withdraw cancel].each do |action|
      it "doesn't let anyone outside the partnership #{action} it" do
        sign_in(create(:user))

        patch public_send(:"#{action}_partner_session_path", partnership, session)

        expect(response).to have_http_status(:not_found)
        expect(session.reload).to be_proposed
      end
    end

    it "says the partnership has ended, rather than that the session can't change" do
      partnership.end!(by: poster)
      sign_in(partner)

      expect { patch confirm_partner_session_path(partnership, session) }.not_to have_enqueued_mail(SessionMailer)

      expect(response).to redirect_to(partner_sessions_path(partnership))
      expect(flash[:alert]).to eq("This partnership has ended.")
    end

    it "doesn't reach a session from another partnership" do
      other_session = create(:session)
      sign_in(partner)

      patch confirm_partner_session_path(partnership, other_session)

      expect(response).to have_http_status(:not_found)
      expect(other_session.reload).to be_proposed
    end

    it "cancels the sessions ahead without emailing about them when the partnership ends" do
      session.confirm!(by: partner)
      sign_in(poster)

      perform_enqueued_jobs { post end_partnership_partner_path(partnership) }

      expect(session.reload).to have_attributes(status: "cancelled", cancelled_by: nil)
      expect(ActionMailer::Base.deliveries.map(&:subject)).to eq(["Your partnership with Maya has ended"])
    end
  end
end
