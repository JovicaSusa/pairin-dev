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
end
