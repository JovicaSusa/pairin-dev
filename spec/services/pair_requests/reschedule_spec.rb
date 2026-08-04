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

    it "replaces the period with the new one" do
      old_period = pair_request.periods.first

      call

      expect(pair_request.reload.periods.pluck(:id)).not_to include(old_period.id)
      expect(pair_request.periods.first.start_at).to eq(new_start_at)
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
