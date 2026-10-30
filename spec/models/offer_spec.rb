RSpec.describe Offer, type: :model do
  # describe "validations" do
  #   it { should validate_presence_of(:message) }
  #   it { should validate_uniqueness_of(:pair_request_id).scoped_to(:offerer_id) }
  # end
  it_behaves_like "activity generatable", :offer

  describe "scopes" do
    describe ".future" do
      subject(:future) { described_class.future }

      let!(:past_offer) { create(:offer, period: past_period, pair_request: past_period.periodable) }
      let!(:future_offer) { create(:offer, period: period, pair_request: period.periodable) }
      let(:past_period) { create(:period, start_at: 1.minute.from_now) }
      let(:period) { create(:period, start_at: 3.minutes.from_now) }

      it "returns only offers with future periods" do
        travel 2.minutes do
          expect(future).to contain_exactly(future_offer)
        end
      end
    end
  end

  describe "its period" do
    it "is its own, not one of the request's" do
      offer = create(:offer)

      expect(offer.period.periodable).to eq(offer)
      expect(offer.period.end_at - offer.period.start_at).to eq(offer.pair_request.duration.minutes)
    end
  end

  describe "booking a slot" do
    let(:pair_request) { create(:pair_request, duration: 60) }
    let(:slot) { PairRequests::BookableSlots.call(pair_request).first }

    def book(start_at)
      build(:offer, pair_request:, with_period: false).tap { |offer| offer.build_period(start_at:) }
    end

    it "accepts one of the request's bookable slots" do
      expect(book(slot.start_at).save(context: :booking)).to be(true)
    end

    it "rejects a time that isn't a bookable slot" do
      offer = book(slot.start_at + 10.minutes)

      expect(offer.save(context: :booking)).to be(false)
      expect(offer.errors[:period]).to include("isn't one of this request's open slots")
    end

    it "needs a slot" do
      offer = build(:offer, pair_request:, with_period: false)

      expect(offer.save(context: :booking)).to be(false)
      expect(offer.errors[:period]).to be_present
    end
  end

  describe ".accepted" do
    subject(:accepted) { described_class.accepted }

    let!(:accepted_offer) { create(:offer, :accepted) }
    let!(:not_accepted_offer) { create(:offer) }

    it { is_expected.to contain_exactly(accepted_offer) }
  end
end
