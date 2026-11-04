RSpec.describe Offer, type: :model do
  # describe "validations" do
  #   it { should validate_presence_of(:message) }
  #   it { should validate_uniqueness_of(:pair_request_id).scoped_to(:offerer_id) }
  # end
  it_behaves_like "activity generatable", :offer

  it "doesn't need a time" do
    expect(build(:offer)).to be_valid
    expect(create(:offer).period).to be_nil
  end

  it "keeps an old application's time" do
    offer = create(:offer, with_old_period: true)

    expect(offer.reload.period.periodable).to eq(offer)
  end

  describe "its clock, which starts when someone applies" do
    let(:offer) { create(:offer) }

    it "reminds the poster after 24 hours" do
      expect(offer.reminder_at).to eq(offer.created_at + 24.hours)
    end

    it "expires after 72 hours" do
      travel_to(offer.created_at + 72.hours - 1.minute) { expect(offer).not_to be_expired }
      travel_to(offer.created_at + 72.hours + 1.second) do
        expect(offer).to be_expired
        expect(offer.status).to eq("EXPIRED")
      end
    end

    it "ignores an old application's time" do
      old = create(:offer, with_old_period: true)

      travel_to(old.period.start_at + 1.hour) { expect(old).not_to be_expired }
    end
  end

  describe ".accepted" do
    subject(:accepted) { described_class.accepted }

    let!(:accepted_offer) { create(:offer, :accepted) }
    let!(:not_accepted_offer) { create(:offer) }

    it { is_expected.to contain_exactly(accepted_offer) }
  end
end
