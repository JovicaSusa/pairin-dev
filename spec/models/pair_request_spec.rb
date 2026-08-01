RSpec.describe PairRequest, type: :model do
  it_behaves_like "activity generatable", :pair_request

  describe "validations" do
    describe "mode" do
      let(:pair_request) { build(:pair_request, with_periods: false) }

      it "allows values in the allowed set" do
        pair_request.mode = "immediate"

        expect(pair_request).to be_valid
      end

      it "rejects values outside the allowed set" do
        pair_request.mode = "whenever"

        expect(pair_request).to be_invalid
        expect(pair_request.errors[:mode]).to be_present
      end
    end

    describe "wait_minutes" do
      let(:pair_request) { build(:pair_request, with_periods: false) }

      it "allows nil" do
        pair_request.wait_minutes = nil

        expect(pair_request).to be_valid
      end

      it "allows values in the allowed set" do
        pair_request.wait_minutes = 30

        expect(pair_request).to be_valid
      end

      it "rejects values outside the allowed set" do
        pair_request.wait_minutes = 45

        expect(pair_request).to be_invalid
        expect(pair_request.errors[:wait_minutes]).to be_present
      end
    end

    describe "platform" do
      let(:pair_request) { build(:pair_request, with_periods: false) }

      it "allows blank" do
        pair_request.platform = nil

        expect(pair_request).to be_valid
      end

      it "allows values in the allowed set" do
        pair_request.platform = "zoom"

        expect(pair_request).to be_valid
      end

      it "rejects values outside the allowed set" do
        pair_request.platform = "carrier_pigeon"

        expect(pair_request).to be_invalid
        expect(pair_request.errors[:platform]).to be_present
      end
    end
  end

  describe "scopes" do
    describe ".scheduled_active" do
      subject(:scheduled_active) { described_class.scheduled_active }

      let!(:scheduled_request) { create(:pair_request, mode: "scheduled") }
      let!(:immediate_request) { create(:pair_request, :immediate) }
      let!(:past_scheduled_request) do
        create(:pair_request, mode: "scheduled", with_periods: false).tap do |pair_request|
          create(:period, periodable: pair_request, start_at: 1.minute.from_now)
        end
      end

      it "returns only active scheduled requests" do
        travel 2.minutes do
          expect(scheduled_active).to contain_exactly(scheduled_request)
        end
      end
    end

    describe ".live_now" do
      subject(:live_now) { described_class.live_now }

      let!(:live_request) do
        pair_request = create(:pair_request, :immediate, wait_minutes: 15, with_periods: false)
        create(:period, periodable: pair_request, start_at: Time.current)
        pair_request
      end

      let!(:expired_request) do
        pair_request = create(:pair_request, :immediate, wait_minutes: 15, with_periods: false)
        period = create(:period, periodable: pair_request, start_at: Time.current)
        period.update_column(:start_at, 20.minutes.ago)
        pair_request
      end

      let!(:scheduled_request) { create(:pair_request, mode: "scheduled") }

      let!(:matched_request) do
        pair_request = create(:pair_request, :immediate, wait_minutes: 15, with_periods: false)
        create(:period, periodable: pair_request, start_at: Time.current)
        create(:offer, :accepted, pair_request:)
        pair_request
      end

      it "returns only unmatched immediate requests still within their wait window" do
        expect(live_now).to contain_exactly(live_request)
      end
    end
  end

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
