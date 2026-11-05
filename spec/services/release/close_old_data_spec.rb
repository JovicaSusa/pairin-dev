require "rails_helper"
require "rake"

RSpec.describe Release::CloseOldData, type: :unit do
  subject(:task) { described_class.new(before: cutoff) }

  let(:cutoff) { 1.hour.ago }

  def old(record) = record.tap { |r| r.update_columns(created_at: 2.days.ago) }

  let(:old_search) { old(create(:pair_request)) }
  let(:new_search) { create(:pair_request) }

  it "switches old searches Off, and leaves ones from after the deploy" do
    old_search
    new_search

    task.apply!

    expect(old_search.reload).to be_paused
    expect(new_search.reload).not_to be_paused
  end

  it "keeps the time an old search was already switched off" do
    old_search.update_columns(paused_at: 5.days.ago)
    at = old_search.reload.paused_at

    task.apply!

    expect(old_search.reload.paused_at).to eq(at)
  end

  it "ends old unanswered applications, and leaves new ones" do
    waiting = old(create(:offer, pair_request: old_search))
    fresh = create(:offer, pair_request: new_search)

    task.apply!

    expect(waiting.reload).to be_ended
    expect(waiting.status).to eq("PENDING")
    expect(fresh.reload).not_to be_ended
  end

  it "leaves open chats and old accepted applications alone, but reports them" do
    talking = old(create(:offer, pair_request: old_search))
    talking.post_message(old_search.user, "Hi")
    accepted = old(create(:offer, :accepted, pair_request: old_search))
    accepted.update_columns(replied_at: accepted.accepted_at)

    expect(task.report.chats_open).to eq(2)

    task.apply!

    expect(talking.reload).not_to be_ended
    expect(accepted.reload).not_to be_ended
  end

  it "keeps conversations that had already ended as they were" do
    ended = old(create(:offer, pair_request: old_search))
    ended.not_a_match!(by: old_search.user, reason: "No")
    at = ended.reload.ended_at

    task.apply!

    expect(ended.reload).to have_attributes(ended_at: at, end_reason: "No", ended_by: old_search.user)
  end

  it "sends no email and no live signal" do
    old(create(:offer, pair_request: old_search))

    expect {
      expect { task.apply! }.not_to have_enqueued_mail
    }.not_to have_broadcasted_to(old_search.user).from_channel(ConversationsChannel)
  end

  it "stops the old system's queued jobs doing anything" do
    waiting = old(create(:offer, pair_request: old_search))
    task.apply!
    old_search.update_columns(paused_at: nil)

    expect { OfferExpiryJob.perform_now(waiting.reload) }.not_to have_enqueued_mail
    expect { OfferReminderJob.perform_now(waiting) }.not_to have_enqueued_mail
    expect(old_search.reload).not_to be_paused
  end

  it "doesn't send a polite email when a closed search later finds a partner" do
    Rails.configuration.x.send_suggestion_emails = true
    waiting = old(create(:offer, pair_request: old_search))
    talking = old(create(:offer, pair_request: old_search))
    talking.post_message(old_search.user, "Hi")
    task.apply!
    talking.propose_partnership!(by: talking.offerer)

    expect { talking.accept_proposal!(by: old_search.user) }
      .not_to have_enqueued_mail(OfferMailer, :search_filled_email).with(params: { offer: waiting }, args: [])
  ensure
    Rails.configuration.x.send_suggestion_emails = false
  end

  it "keeps old booked times" do
    offer = old(create(:offer, pair_request: old_search, with_old_period: true))

    expect { task.apply! }.not_to change(Period, :count)
    expect(offer.reload.period).to be_present
  end

  it "gives an old search the default commitment" do
    expect(old_search.commitment).to eq("one_to_three_months")
  end

  it "is safe to run twice" do
    waiting = old(create(:offer, pair_request: old_search))
    task.apply!
    at = waiting.reload.ended_at

    travel 1.hour do
      task.apply!
    end

    expect(waiting.reload.ended_at).to eq(at)
    expect(task.report).to have_attributes(searches_on: 0, applications_waiting: 0)
  end

  it "lets a poster switch their search back on afterwards" do
    old_search
    task.apply!

    expect(old_search.reload.switch_on!).to be_truthy
    expect(old_search.reload).not_to be_paused
  end

  it "counts what it would do" do
    old(create(:offer, pair_request: old_search))
    create(:pair_request)

    expect(task.report).to have_attributes(searches_on: 1, applications_waiting: 1, chats_open: 0)
  end

  describe "the rake task" do
    let(:rake_task) do
      Rails.application.load_tasks unless Rake::Task.task_defined?("release:close_old_data")
      Rake::Task["release:close_old_data"].tap(&:reenable)
    end

    def with_env(values)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).with("BEFORE").and_return(values[:before]) if values.key?(:before)
      allow(ENV).to receive(:fetch).with("BEFORE").and_raise(KeyError) unless values.key?(:before)
      allow(ENV).to receive(:[]).with("APPLY").and_return(values[:apply])
    end

    before { old_search }

    it "only reports by default" do
      with_env(before: cutoff.utc.iso8601)

      expect { rake_task.invoke }.to output(/Searches still On:\s+1.*Nothing changed/m).to_stdout

      expect(old_search.reload).not_to be_paused
    end

    it "changes data with APPLY=1, and reports again" do
      with_env(before: cutoff.utc.iso8601, apply: "1")

      expect { rake_task.invoke }.to output(/Done\. Afterwards:.*Searches still On:\s+0/m).to_stdout

      expect(old_search.reload).to be_paused
    end

    it "needs a cutoff" do
      with_env({})

      expect { rake_task.invoke }.to raise_error(SystemExit).and output(/Usage/).to_stderr
    end

    it "refuses a cutoff in the future, which would catch new searches" do
      with_env(before: 1.hour.from_now.utc.iso8601, apply: "1")

      expect { rake_task.invoke }.to raise_error(SystemExit).and output(/in the future/).to_stderr

      expect(old_search.reload).not_to be_paused
    end
  end
end
