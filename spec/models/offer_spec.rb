RSpec.describe Offer, type: :model do
  # describe "validations" do
  #   it { should validate_presence_of(:message) }
  #   it { should validate_uniqueness_of(:pair_request_id).scoped_to(:offerer_id) }
  # end

  describe "scopes" do
    describe ".future" do
      subject(:future) { described_class.future }

      let!(:past_offer) { create(:offer, period: past_period) }
      let!(:future_offer) { create(:offer, period: period) }
      let(:past_period) { create(:period, start_at: 1.minute.from_now) }
      let(:period) { create(:period, start_at: 3.minutes.from_now) }

      it "returns only offers with future periods" do
        travel 2.minutes do
          expect(future).to contain_exactly(future_offer)
        end
      end
    end
  end

  describe ".accepted" do
    subject(:accepted) { described_class.accepted }

    let!(:accepted_offer) { create(:offer, :accepted) }
    let!(:not_accepted_offer) { create(:offer) }

    it { is_expected.to contain_exactly(accepted_offer) }
  end
end
