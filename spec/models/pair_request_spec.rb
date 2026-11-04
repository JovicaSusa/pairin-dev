RSpec.describe PairRequest, type: :model do
  it_behaves_like "activity generatable", :pair_request

  describe "#has_accepted_offer?" do
    subject(:has_accepted_offer?) { pair_request.has_accepted_offer? }

    let(:pair_request) { create(:pair_request) }

    context "when pair request has accepted offer" do
      before { create(:offer, :accepted, pair_request:) }

      it { is_expected.to be true }
    end

    context "when pair request doesn't have accepted offer" do
      it { is_expected.to be false }
    end
  end

  describe "commitment" do
    it "defaults to 1–3 months" do
      expect(PairRequest.new.commitment).to eq("one_to_three_months")
      expect(PairRequest.new.commitment_label).to eq("1–3 months")
    end

    it "only accepts the listed options" do
      expect(build(:pair_request, commitment: "open_ended")).to be_valid
      expect(build(:pair_request, commitment: "forever").tap(&:validate).errors[:commitment]).to be_present
    end
  end

  describe "#switch_on!" do
    it "works without weekly hours" do
      pair_request = create(:pair_request, paused_at: 1.hour.ago)

      expect(pair_request.switch_on!).to be(true)
      expect(pair_request.reload).not_to be_paused
    end
  end
end
