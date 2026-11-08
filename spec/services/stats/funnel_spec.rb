require "rails_helper"
require "rake"

RSpec.describe Stats::Funnel, type: :unit do
  subject(:funnel) { described_class.new(since:) }

  let(:since) { Time.zone.local(2026, 12, 1) }

  around { |example| travel_to(since + 1.hour) { example.run } }

  def application(**attrs)
    create(:offer, pair_request: create(:pair_request), **attrs)
  end

  def chat = application.tap { |offer| offer.post_message(offer.poster, "Hi") }

  def partnership
    offer = chat
    offer.propose_partnership!(by: offer.offerer)
    offer.accept_proposal!(by: offer.poster)
  end

  def answer(partnership, user, week, yes: true, at: Time.current)
    CheckIn.create!(partnership:, user:, week:, worked_together: yes, answered_at: at)
  end

  describe "each stage" do
    before do
      create(:pair_request)
      application
      chat
      chat.tap { |offer| offer.propose_partnership!(by: offer.offerer) }
      declined = chat
      declined.propose_partnership!(by: declined.offerer)
      declined.decline_proposal!(by: declined.poster)
      partnership
      partnership.end!(by: User.first)
    end

    it "counts what happened" do
      expect(funnel.searches_posted).to eq(7)
      expect(funnel.applications).to eq(6)
      expect(funnel.chats_opened).to eq(5)
      expect(funnel.proposals).to eq(4)
      expect(funnel.partnerships_formed).to eq(2)
      expect(funnel.partnerships_ended).to eq(1)
    end
  end

  it "leaves out anything before the date" do
    partnership
    [PairRequest, Offer, Partnership].each { |model| model.update_all(created_at: since - 1.day) }

    expect([funnel.searches_posted, funnel.applications, funnel.chats_opened, funnel.proposals, funnel.partnerships_formed]).to all(eq(0))
  end

  describe "pairs with a Yes" do
    let(:pair) { partnership }

    it "needs a Yes, and either partner's is enough" do
      answer(pair, pair.offer.poster, 1, yes: false)
      expect(funnel.pairs_with_a_yes).to eq(0)

      answer(pair, pair.offer.offerer, 1)
      expect(funnel.pairs_with_a_yes).to eq(1)
    end

    it "counts a pair once when both said Yes" do
      answer(pair, pair.offer.poster, 1)
      answer(pair, pair.offer.offerer, 1)

      expect(funnel.pairs_with_a_yes).to eq(1)
    end

    it "only meets the target within 30 days" do
      answer(pair, pair.offer.poster, 5, at: since + 31.days)

      expect(funnel.pairs_with_a_yes).to eq(1)
      expect(funnel.pairs_with_a_yes_in_time).to eq(0)

      answer(pair, pair.offer.poster, 4, at: since + 30.days)

      expect(funnel.pairs_with_a_yes_in_time).to eq(1)
    end
  end

  describe "the follow-up" do
    let(:pair) { partnership }

    it "needs 3 separate weeks, however many people answered" do
      answer(pair, pair.offer.poster, 1)
      answer(pair, pair.offer.offerer, 1)
      answer(pair, pair.offer.poster, 2)
      expect(funnel.pairs_with_three_yes_weeks_in_time).to eq(0)

      answer(pair, pair.offer.poster, 3)
      expect(funnel.pairs_with_three_yes_weeks_in_time).to eq(1)
    end

    it "only counts Yes answers within 60 days" do
      answer(pair, pair.offer.poster, 1, at: since + 10.days)
      answer(pair, pair.offer.poster, 2, at: since + 20.days)
      answer(pair, pair.offer.poster, 9, at: since + 61.days)

      expect(funnel.pairs_with_three_yes_weeks_in_time).to eq(0)
    end
  end

  describe "sessions" do
    # Sessions can't be created in the past, so each is created ahead and then
    # moved to have ended an hour ago.
    def session(pair, status: "proposed", by: pair.offer.offerer, ended: false, **attrs)
      create(:session, partnership: pair, proposed_by: by, status:, **attrs).tap do |s|
        s.update_columns(start_at: 2.hours.ago, end_at: 1.hour.ago) if ended
      end
    end

    def said(session, user, happened)
      session.answers.create!(user:).answer!(happened)
    end

    it "counts proposed, confirmed and completed sessions, and pairs with a completed one" do
      first = partnership
      second = partnership
      partnership # a pair with no sessions

      # Tally: 9 proposed (7 + 2). 6 confirmed: still ahead, called off, both
      # Yes ones, the No one and the unanswered one. 2 completed, both in the
      # first pair, so 1 pair.
      session(first)                                                  # proposed, never answered
      session(first, status: "declined")
      session(first, status: "withdrawn")
      session(first, status: "confirmed")                             # confirmed, still ahead
      called_off = session(first, status: "confirmed")
      called_off.cancel!(by: first.offer.poster)                      # confirmed, then cancelled
      yes = session(first, status: "confirmed", ended: true)
      said(yes, first.offer.poster, false)
      said(yes, first.offer.offerer, true)                            # completed: one Yes is enough
      also_yes = session(first, status: "confirmed", ended: true)
      said(also_yes, first.offer.poster, true)                        # completed: the same pair again
      no = session(second, status: "confirmed", ended: true)
      said(no, second.offer.poster, false)                            # confirmed, didn't happen
      session(second, status: "confirmed", ended: true)               # confirmed, nobody answered

      expect(funnel.sessions_proposed).to eq(9)
      expect(funnel.sessions_confirmed).to eq(6)
      expect(funnel.sessions_completed).to eq(2)
      expect(funnel.pairs_with_a_completed_session).to eq(1)
    end

    it "counts a confirmed session even after ending the partnership cancelled it, but not a proposal it cancelled" do
      pair = partnership
      confirmed = session(pair)
      confirmed.confirm!(by: pair.offer.poster)
      session(pair) # only ever proposed
      pair.end!(by: pair.offer.poster)

      expect(Session.pluck(:status)).to all(eq("cancelled"))
      expect(funnel.sessions_proposed).to eq(2)
      expect(funnel.sessions_confirmed).to eq(1)
    end

    it "only counts the sessions of partnerships formed since the date, so the stages narrow" do
      older = partnership
      done = session(older, status: "confirmed", ended: true)
      said(done, older.offer.poster, true)
      older.update_columns(created_at: since - 1.day)

      newer = partnership
      session(newer)

      expect(funnel.partnerships_formed).to eq(1)
      expect(funnel.sessions_proposed).to eq(1)
      expect([funnel.sessions_confirmed, funnel.sessions_completed, funnel.pairs_with_a_completed_session]).to all(eq(0))
    end
  end

  describe "the report and the task" do
    it "prints every stage and both targets" do
      pair = partnership
      answer(pair, pair.offer.poster, 1)

      report = funnel.report

      ["Searches posted:", "Applications:", "Chats opened:", "Proposals:", "Partnerships formed:",
       "Sessions proposed:", "Sessions confirmed:", "Completed sessions:", "Pairs, 1+ session done:",
       "Pairs with a Yes:", "Yes weeks:", "Partnerships ended:"].each do |label|
        expect(report).to include(label)
      end
      expect(report).to include("Target: 1 of 3 pairs with a Yes within 30 days")
      expect(report).to include("Follow-up: 0 pairs with 3 Yes weeks within 60 days")
    end

    it "runs from rake, and explains itself without a date" do
      Rails.application.load_tasks unless Rake::Task.task_defined?("stats:funnel")
      task = Rake::Task["stats:funnel"]

      task.reenable

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SINCE").and_return("2026-12-01")
      expect { task.invoke }.to output(/Partner funnel since 2026-12-01/).to_stdout
      task.reenable

      allow(ENV).to receive(:fetch).with("SINCE").and_return("soon")
      expect { task.invoke }.to raise_error(SystemExit).and output(/Usage/).to_stderr
      task.reenable
    end
  end
end
