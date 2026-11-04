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

  describe "the report and the task" do
    it "prints every stage and both targets" do
      pair = partnership
      answer(pair, pair.offer.poster, 1)

      report = funnel.report

      ["Searches posted:", "Applications:", "Chats opened:", "Proposals:", "Partnerships formed:", "Pairs with a Yes:", "Yes weeks:", "Partnerships ended:"].each do |label|
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
