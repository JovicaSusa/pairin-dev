require 'rails_helper'

RSpec.describe PairRequests::Reschedule, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(pair_request, periods_attributes) }

    let(:pair_request) { create(:pair_request, :immediate, wait_minutes: 30) }
    let(:new_start_at) { 3.days.from_now.change(usec: 0) }
    let(:periods_attributes) { [{ start_at: new_start_at }] }

    it "returns success" do
      expect(call.success?).to be true
    end

    it "flips the mode to scheduled" do
      expect { call }.to change { pair_request.reload.mode }.from("immediate").to("scheduled")
    end

    it "adds the new period without destroying the old one" do
      old_period = pair_request.periods.first

      expect { call }.to change { pair_request.reload.periods.count }.by(1)

      expect(pair_request.periods.pluck(:id)).to include(old_period.id)
      expect(pair_request.periods.find_by(start_at: new_start_at)).to be_present
    end

    context "when the pair request has a pending (not yet accepted) offer" do
      let(:pair_request) do
        pr = create(:pair_request, :immediate, wait_minutes: 15, with_periods: false)
        period = create(:period, periodable: pr, start_at: Time.current)
        period.update_column(:start_at, 30.minutes.ago)
        pr
      end

      let!(:offer) { create(:offer, pair_request:, period: pair_request.periods.first) }

      it "leaves the offer and its period alone" do
        expect { call }.not_to change { Offer.count }
        expect(offer.reload.period).to eq(pair_request.periods.first)
      end

      it "the offer now reads as expired, since its period is in the past" do
        call

        expect(offer.reload.status).to eq("EXPIRED")
      end

      it "still succeeds and reschedules" do
        expect(call.success?).to be true
      end
    end

    context "when the pair request is not in immediate mode" do
      let(:pair_request) { create(:pair_request) }

      it "returns failure" do
        expect(call.success?).to be false
      end

      it "doesn't change the mode" do
        expect { call }.not_to change { pair_request.reload.mode }
      end
    end

    context "when the pair request has already been cancelled" do
      let(:pair_request) { create(:pair_request, :immediate, :cancelled, wait_minutes: 30) }

      it "returns failure" do
        expect(call.success?).to be false
      end
    end

    context "when the pair request already has an accepted offer" do
      before { create(:offer, :accepted, pair_request:) }

      it "returns failure" do
        expect(call.success?).to be false
      end

      it "doesn't change the mode" do
        expect { call }.not_to change { pair_request.reload.mode }
      end
    end
  end
end
