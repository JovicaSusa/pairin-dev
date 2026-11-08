require "rails_helper"

RSpec.describe "Reminders before a session", type: :request do
  include ActiveJob::TestHelper

  let(:poster) { create(:user, name: "Maya", email: "maya@example.com", timezone: "Europe/Berlin") }
  let(:partner) { create(:user, name: "Sam", email: "sam@example.com", timezone: "America/New_York") }
  let(:offer) { create(:offer, pair_request: create(:pair_request, user: poster), offerer: partner) }
  let!(:partnership) do
    offer.post_message(poster, "Hi")
    offer.propose_partnership!(by: partner)
    offer.accept_proposal!(by: poster)
  end

  # 2030-03-04 17:30 UTC: 18:30 in Berlin, 12:30 in New York.
  let(:starts) { Time.utc(2030, 3, 4, 17, 30) }

  def proposed(call_link: "https://meet.google.com/abc")
    create(:session, partnership:, proposed_by: poster, start_at: starts, end_at: starts + 1.hour, call_link:)
  end

  # Confirmed through the real transition, a day ahead unless said otherwise.
  def confirmed(at: starts - 1.day, **attrs)
    session = proposed(**attrs)
    travel_to(at) { session.confirm!(by: partner) }
    session.reload
  end

  def run_job = RemindAboutSessionsJob.perform_now

  def reminder_sent = have_enqueued_mail(SessionMailer, :reminder_email)

  def body_of(mail) = CGI.unescapeHTML(mail.html_part ? mail.html_part.body.to_s : mail.body.to_s)

  describe "when it goes out" do
    it "sends both partners a reminder in the hour before a confirmed session" do
      confirmed
      travel_to starts - 1.hour + 1.minute

      expect { run_job }.to reminder_sent.twice
    end

    it "doesn't send earlier than an hour before" do
      confirmed
      travel_to starts - 1.hour - 5.minutes

      expect { run_job }.not_to reminder_sent
    end

    it "doesn't send once the session has started" do
      confirmed
      travel_to starts + 1.minute

      expect { run_job }.not_to reminder_sent
    end

    it "sends each partner one reminder, however often the job runs" do
      session = confirmed
      travel_to starts - 50.minutes

      expect { run_job }.to reminder_sent.twice
      expect { run_job }.not_to reminder_sent
      travel 5.minutes
      expect { run_job }.not_to reminder_sent
      expect(session.reload.reminded_at).to be_present
    end

    it "tries again on the next run if queueing the reminder failed" do
      session = confirmed
      travel_to starts - 50.minutes
      failing = true
      allow(SessionMailer).to receive(:with).and_wrap_original do |original, **args|
        message = original.call(**args)
        if failing
          failing = false
          allow(message).to receive(:reminder_email).and_raise(StandardError, "queue down")
        end
        message
      end

      expect { run_job }.not_to reminder_sent
      expect(session.reload.reminded_at).to be_nil

      travel 5.minutes
      expect { run_job }.to reminder_sent.twice
      expect(session.reload.reminded_at).to be_present
    end

    it "still reminds the other sessions when one fails" do
      first = confirmed
      second = create(:session, partnership:, proposed_by: poster, start_at: starts + 10.minutes, end_at: starts + 70.minutes)
      travel_to(starts - 1.day) { second.confirm!(by: partner) }
      travel_to starts - 45.minutes
      allow(SessionMailer).to receive(:with).and_wrap_original do |original, **args|
        raise StandardError, "bad row" if args[:session].id == first.id

        original.call(**args)
      end

      expect { run_job }.to reminder_sent.twice
      expect(second.reload.reminded_at).to be_present
      expect(first.reload.reminded_at).to be_nil
    end
  end

  describe "when it doesn't" do
    before { travel_to(starts - 1.day) }

    it "skips proposals nobody confirmed" do
      proposed
      travel_to starts - 30.minutes

      expect { run_job }.not_to reminder_sent
    end

    it "skips cancelled sessions" do
      session = confirmed
      travel_to(starts - 2.hours) { session.cancel!(by: poster) }
      travel_to starts - 30.minutes

      expect { run_job }.not_to reminder_sent
    end

    it "skips sessions in a partnership that has ended" do
      confirmed
      travel_to(starts - 2.hours) { partnership.end!(by: poster) }
      travel_to starts - 30.minutes

      expect { run_job }.not_to reminder_sent
    end

    it "skips sessions when the chat behind the partnership has ended, even if the partnership row hasn't" do
      session = confirmed
      offer.update_columns(ended_at: starts - 2.hours)
      travel_to starts - 30.minutes

      expect { run_job }.not_to reminder_sent
      expect(session.reload.reminded_at).to be_nil
    end

    it "skips sessions confirmed less than an hour before they start" do
      confirmed(at: starts - 59.minutes)
      travel_to starts - 30.minutes

      expect { run_job }.not_to reminder_sent
    end

    it "still reminds a session confirmed exactly an hour before" do
      confirmed(at: starts - 1.hour)
      travel_to starts - 55.minutes

      expect { run_job }.to reminder_sent.twice
    end

    it "sends nothing if the session is cancelled between queueing and sending" do
      session = confirmed
      travel_to starts - 50.minutes
      run_job
      session.cancel!(by: poster)
      ActionMailer::Base.deliveries.clear

      perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)

      expect(ActionMailer::Base.deliveries.map(&:subject)).not_to include(a_string_including("Reminder"))
    end
  end

  describe "the email" do
    it "has the time in each person's timezone, the call link and a link to the Workspace, and no unsubscribe" do
      confirmed
      travel_to starts - 50.minutes
      perform_enqueued_jobs { run_job }

      mails = ActionMailer::Base.deliveries.index_by { _1.to.sole }
      expect(mails.keys).to contain_exactly("maya@example.com", "sam@example.com")

      to_sam = mails.fetch("sam@example.com")
      expect(to_sam.subject).to eq("Reminder: your session with Maya at 12:30")
      body = body_of(to_sam)
      expect(body).to include("Your session with Maya is coming up", "Monday 4 March", "12:30–13:30", "America/New_York", "https://meet.google.com/abc", "/partners/#{partnership.id}/sessions")
      expect(to_sam["List-Unsubscribe"]).to be_nil
      expect(body).not_to include("/unsubscribe/")

      expect(mails.fetch("maya@example.com").subject).to eq("Reminder: your session with Sam at 18:30")
    end

    it "leaves out the call link when there isn't one" do
      confirmed(call_link: "")
      travel_to starts - 50.minutes
      perform_enqueued_jobs { run_job }

      expect(body_of(ActionMailer::Base.deliveries.last)).not_to include("Call link:")
    end
  end

  describe "confirming" do
    it "remembers when a session was confirmed" do
      session = proposed
      travel_to(starts - 3.hours) { session.confirm!(by: partner) }

      expect(session.reload.confirmed_at).to eq(starts - 3.hours)
    end
  end
end
