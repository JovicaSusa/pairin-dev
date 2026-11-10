require "rails_helper"

RSpec.describe "Did it happen?", type: :request do
  include ActiveJob::TestHelper

  let(:poster) { create(:user, name: "Maya", email: "maya@example.com", timezone: "Europe/Berlin") }
  let(:partner) { create(:user, name: "Sam", email: "sam@example.com", timezone: "America/New_York") }
  let(:offer) { create(:offer, pair_request: create(:pair_request, user: poster), offerer: partner) }
  let!(:partnership) do
    offer.post_message(poster, "Hi")
    offer.propose_partnership!(by: partner)
    offer.accept_proposal!(by: poster)
  end

  # Confirmed for 2030-03-04 17:30 UTC, an hour long; tests travel past its end.
  let(:starts) { Time.utc(2030, 3, 4, 17, 30) }
  let!(:session) { create(:session, partnership:, proposed_by: poster, status: "confirmed", start_at: starts, end_at: starts + 1.hour) }

  def run_job = AskWhetherSessionsHappenedJob.perform_now

  def email_sent = have_enqueued_mail(SessionMailer, :did_it_happen_email)

  def answer_for(user) = session.answers.find_by!(user:)

  describe "sending" do
    it "asks nobody before the session has ended" do
      travel_to starts + 59.minutes

      expect { run_job }.not_to email_sent
    end

    it "asks both partners shortly after it ends" do
      travel_to starts + 1.hour + 5.minutes

      expect { run_job }.to email_sent.twice
      expect(session.answers.pluck(:user_id)).to contain_exactly(poster.id, partner.id)
    end

    it "asks each partner at most once" do
      travel_to starts + 1.hour + 5.minutes
      run_job
      travel 15.minutes

      expect { run_job }.not_to email_sent
    end

    it "doesn't ask about sessions that weren't confirmed" do
      # The confirmed one becomes cancelled, and a proposal (never answered) is
      # placed at the same time. A new session can't be created in the past, so
      # it's created later and then moved.
      session.update_columns(status: "cancelled")
      create(:session, partnership:, proposed_by: poster, start_at: starts + 2.hours).tap { _1.update_columns(start_at: starts, end_at: starts + 1.hour) }
      travel_to starts + 1.hour + 5.minutes

      expect { run_job }.not_to email_sent
    end

    it "doesn't ask once the partnership has ended" do
      partnership.update_columns(ended_at: starts - 1.day, ended_by_id: poster.id)
      travel_to starts + 1.hour + 5.minutes

      expect { run_job }.not_to email_sent
    end

    it "doesn't ask when the chat behind the partnership has ended, even if the partnership row hasn't" do
      offer.update_columns(ended_at: starts - 1.day)
      travel_to starts + 1.hour + 5.minutes

      expect { run_job }.not_to email_sent
      expect(session.answers).to be_empty
    end

    it "asks again on the next run if sending failed, instead of skipping that partner for good" do
      travel_to starts + 1.hour + 5.minutes
      failing = true
      allow(SessionMailer).to receive(:with).and_wrap_original do |original, **args|
        message = original.call(**args)
        if failing
          failing = false
          allow(message).to receive(:did_it_happen_email).and_raise(StandardError, "queue down")
        end
        message
      end

      expect { run_job }.to raise_error(StandardError, "queue down")
      expect(session.answers).to be_empty

      expect { run_job }.to email_sent.twice
      expect(session.answers.count).to eq(2)
    end

    # The answer row and its email are queued in one transaction, so the email
    # job must be queued straight away for a failure to roll the row back.
    it "queues the email inside the transaction, not after it commits" do
      expect(SessionMailer.delivery_job.enqueue_after_transaction_commit).to be(false)
    end

    it "doesn't ask about sessions that ended long ago" do
      travel_to starts + 3.days

      expect { run_job }.not_to email_sent
    end

    it "skips someone who opted out of suggestions, and still asks the other" do
      poster.update!(suggestions_opted_out_at: Time.current)
      travel_to starts + 1.hour + 5.minutes

      expect { run_job }.to email_sent.once
      expect(session.answers.pluck(:user_id)).to eq([partner.id])
    end

    it "emails the time in each person's timezone, with Yes and No links and an unsubscribe link" do
      travel_to starts + 1.hour + 5.minutes
      perform_enqueued_jobs { run_job }

      mail = ActionMailer::Base.deliveries.find { _1.to == ["sam@example.com"] }
      expect(mail.subject).to eq("Did your session with Maya happen?")
      body = CGI.unescapeHTML(mail.html_part ? mail.html_part.body.to_s : mail.body.to_s)
      expect(body).to include("Monday 4 March", "12:30–13:30", "America/New_York", "/did-it-happen/", "answer=yes", "answer=no", "/unsubscribe/")
      expect(mail["List-Unsubscribe"]).to be_present
    end
  end

  describe "answering, without signing in" do
    before do
      travel_to starts + 1.hour + 5.minutes
      run_job
    end

    let(:token) { answer_for(partner).generate_token_for(:answer) }

    it "only shows the question when the link is opened, since mail scanners open links" do
      get session_answer_path(token:, answer: "yes")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Did your session with Maya happen?", "Confirm: Yes")
      expect(answer_for(partner).happened).to be_nil
    end

    it "records the answer on submit" do
      post session_answer_path(token:), params: { answer: "yes" }

      expect(response).to redirect_to(session_answer_path(token:))
      expect(answer_for(partner)).to have_attributes(happened: true, answered_at: be_present)
      follow_redirect!
      expect(response.body).to include("You said <strong>yes</strong>")
    end

    it "changes the answer when answered again" do
      post session_answer_path(token:), params: { answer: "yes" }
      post session_answer_path(token:), params: { answer: "no" }

      expect(answer_for(partner).happened).to be(false)
    end

    it "offers the other answer once answered" do
      post session_answer_path(token:), params: { answer: "yes" }
      get session_answer_path(token:)

      expect(response.body).to include("Change to No")
    end

    it "ignores anything but yes or no" do
      post session_answer_path(token:), params: { answer: "maybe" }

      expect(answer_for(partner).happened).to be_nil
    end

    it "keeps the token out of referrers, caches and search engines" do
      get session_answer_path(token:)

      expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.headers["X-Robots-Tag"]).to include("noindex")
    end

    it "refuses a link older than 30 days" do
      token
      travel 31.days

      get session_answer_path(token:)

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("This link isn't valid")
    end

    it "refuses a made-up token" do
      post session_answer_path(token: "nope"), params: { answer: "yes" }

      expect(response).to have_http_status(:not_found)
      expect(SessionAnswer.where.not(happened: nil)).to be_empty
    end
  end

  describe "what counts as completed" do
    before do
      travel_to starts + 1.hour + 5.minutes
      run_job
    end

    it "is completed when at least one partner says yes" do
      answer_for(poster).answer!(false)
      expect(Session.completed).to be_empty
      expect(session.reload.happened).to be(false)

      answer_for(partner).answer!(true)
      expect(Session.completed).to eq([session])
      expect(session.reload.happened).to be(true)
    end

    it "isn't known until someone answers" do
      expect(session.happened).to be_nil
      expect(Session.completed).to be_empty
    end
  end

  describe "the Workspace" do
    def props
      JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
    end

    it "shows whether each past session took place" do
      travel_to starts + 1.hour + 5.minutes
      run_job
      answer_for(partner).answer!(true)
      sign_in(poster)

      get partner_sessions_path(partnership)

      expect(props.dig("partnership", "sessions", "past").sole).to include("id" => session.id, "happened" => true)
    end
  end
end
