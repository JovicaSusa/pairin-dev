RSpec.describe Period, type: :model do
  describe "validations" do
    describe "dates in future" do
      let(:period) { build(:period, start_at: 40.minutes.ago, end_at: 10.minutes.ago) }

      it "sets expected error" do
        skip "fix when setting end_at is moved out of the model"
        expect(period.valid?).to be false
        expect(period.errors[:end_at]).to contain_exactly("must be in future")
        expect(period.errors[:start_at]).to contain_exactly("must be in future")
      end
    end
  end

  describe "scopes" do
    describe ".future" do
      subject(:future) { described_class.future }

      let!(:past_period) { create(:period, start_at: 1.minute.from_now) }
      let!(:future_period) { create(:period, start_at: 3.minutes.from_now) }

      it "returns only future periods" do
        travel 2.minutes do
          expect(future).to contain_exactly(future_period)
        end
      end
    end
  end
end
