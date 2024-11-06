RSpec.describe ActivitiesSetup::Proxy, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(record) }

    context "when record is PairRequest" do
      let(:record) { build(:pair_request) }

      it "calls expected service" do
        expect(ActivitiesSetup::FromPairRequest).to receive(:call).with(record)

        call
      end
    end

    context "when record is Offer" do
      let(:record) { build(:offer) }

      it "calls expected service" do
        expect(ActivitiesSetup::FromOffer).to receive(:call).with(record)

        call
      end
    end

    context "when record is Participation" do
      let(:record) { build(:participation) }

      it "calls expected service" do
        expect(ActivitiesSetup::FromParticipation).to receive(:call).with(record)

        call
      end
    end
  end
end
