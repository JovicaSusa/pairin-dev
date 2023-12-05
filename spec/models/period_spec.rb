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
end
