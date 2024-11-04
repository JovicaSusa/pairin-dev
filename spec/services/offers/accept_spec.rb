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

    it "creates expected session" do
      expect { call }.to change { Session.count }.by(1)

      session = Session.last

      expect(session.sessionable).to eq(offer.pair_request)
      expect(session.start_at).to eq(offer.period.start_at)
      expect(session.end_at).to eq(offer.period.end_at)
    end

    it "creates expected participants" do
      expect { call }.to change { Participation.count }.by(2)

      initiator = Participation.find_by(role: "initiator")
      pair = Participation.find_by(role: "pair")

      expect(initiator.participant).to eq(offer.pair_request.user)
      expect(pair.participant).to eq(offer.offerer)
    end

    context "when failure" do
      before { allow(Session).to receive(:create!).and_raise(ActiveRecord::RecordInvalid) }

      it "returns failure" do
        expect(call.success?).to be false
      end

      it "doesn't create none of records" do
        expect { call }
          .to not_change { offer.reload.accepted_at }.from(nil)
          .and not_change { Session.count }
          .and not_change { Participation.count }
      end
    end
  end
end
