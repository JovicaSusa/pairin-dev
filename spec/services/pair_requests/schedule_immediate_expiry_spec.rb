require 'rails_helper'

RSpec.describe PairRequests::ScheduleImmediateExpiry, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(pair_request) }

    let(:pair_request) { create(:pair_request, :immediate, wait_minutes: 30) }

    it "returns true" do
      expect(call).to be true
    end

    it "schedules the immediate expiry job for the period's start_at + wait_minutes" do
      period = pair_request.periods.first

      expect { call }
        .to have_enqueued_job(PairRequests::ImmediateExpiryJob)
        .with(pair_request.id)
        .at(period.start_at + 30.minutes)
    end

    context "when the pair request is not in immediate mode" do
      let(:pair_request) { create(:pair_request) }

      it "returns false and does not enqueue a job" do
        expect { expect(call).to be false }.not_to have_enqueued_job(PairRequests::ImmediateExpiryJob)
      end
    end
  end
end
