RSpec.describe Offers::Accept, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(offer) }

    let(:offer) { create(:offer) }

    it "returns success" do
      expect(call.success?).to be true
    end

    it "marks offer as accepted" do
      freeze_time do
        expect { call }.to change { offer.accepted_at }.from(nil).to(Time.current)
      end
    end

    it "doesn't create a session" do
      expect { call }
        .to not_change { Session.count }
        .and not_change { Participation.count }
    end

    context "when failure" do
      context "when pair request already have accepted offer" do
        before { create(:offer, :accepted, pair_request: offer.pair_request) }

        it "returns failure" do
          expect(call.success?).to be false
        end
      end

      context "when there's an error" do
        before { allow(offer).to receive(:update!).and_raise(ActiveRecord::RecordInvalid) }

        it "returns failure" do
          expect(call.success?).to be false
        end

        it "doesn't accept the offer" do
          expect { call }.to not_change { offer.reload.accepted_at }.from(nil)
        end
      end
    end
  end
end
