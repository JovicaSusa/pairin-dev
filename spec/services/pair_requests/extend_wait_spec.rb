require 'rails_helper'

RSpec.describe PairRequests::ExtendWait, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(pair_request) }

    let(:pair_request) { create(:pair_request, :immediate, wait_minutes: 30) }

    it "returns true" do
      expect(call).to be true
    end

    it "bumps the period's start_at to now" do
      freeze_time do
        expect { call }.to change { pair_request.periods.first.reload.start_at }.to(Time.current)
      end
    end

    it "recomputes end_at from the pair request's duration" do
      call

      period = pair_request.periods.first.reload

      expect(period.end_at).to eq(period.start_at + pair_request.duration.minutes)
    end

    it "re-enqueues the immediate expiry job for the new wait window" do
      freeze_time do
        expect { call }
          .to have_enqueued_job(PairRequests::ImmediateExpiryJob)
          .with(pair_request.id)
          .at(30.minutes.from_now)
      end
    end

    context "when the pair request already has an accepted offer" do
      before { create(:offer, :accepted, pair_request:) }

      it "returns false" do
        expect(call).to be false
      end

      it "doesn't change the period" do
        expect { call }.not_to change { pair_request.periods.first.reload.start_at }
      end

      it "doesn't enqueue a job" do
        expect { call }.not_to have_enqueued_job(PairRequests::ImmediateExpiryJob)
      end
    end

    context "when the pair request is not in immediate mode" do
      let(:pair_request) { create(:pair_request) }

      it "returns false" do
        expect(call).to be false
      end
    end
  end
end
