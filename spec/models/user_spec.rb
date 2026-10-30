RSpec.describe User, type: :model do
  describe ".old_enough?" do
    let(:today) { Date.new(2026, 11, 2) }

    it "counts someone turning 16 today" do
      expect(described_class.old_enough?(Date.new(2010, 11, 2), today:)).to be(true)
    end

    it "refuses someone turning 16 tomorrow" do
      expect(described_class.old_enough?(Date.new(2010, 11, 3), today:)).to be(false)
    end

    it "treats a 29 February birthday as reached on 28 February in other years" do
      expect(described_class.old_enough?(Date.new(2008, 2, 29), today: Date.new(2024, 2, 28))).to be(false)
      expect(described_class.old_enough?(Date.new(2008, 2, 29), today: Date.new(2024, 2, 29))).to be(true)
      expect(described_class.old_enough?(Date.new(2012, 2, 29), today: Date.new(2028, 2, 29))).to be(true)
    end
  end

  describe "date of birth" do
    it "is required for a new account" do
      expect(build(:user, date_of_birth: nil)).not_to be_valid
    end

    it "can't be in the future" do
      expect(build(:user, date_of_birth: Date.tomorrow).tap(&:validate).errors[:date_of_birth]).to include("can't be in the future")
    end

    it "isn't required to keep using an existing account" do
      user = create(:user)
      user.update_column(:date_of_birth, nil)

      expect(user.reload).to be_valid
    end
  end
end
