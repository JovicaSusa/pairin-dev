RSpec.describe User, type: :model do
  describe "github_url" do
    it "is optional, and blank is saved as nothing" do
      expect(build(:user, github_url: nil)).to be_valid
      expect(build(:user, github_url: "  ").github_url).to be_nil
    end

    it "accepts a github.com link" do
      expect(build(:user, github_url: "https://github.com/ada")).to be_valid
      expect(build(:user, github_url: "https://www.github.com/ada")).to be_valid
    end

    it "adds https when it's left off" do
      expect(build(:user, github_url: " github.com/ada ").github_url).to eq("https://github.com/ada")
    end

    it "refuses anything that isn't a link to someone on github.com" do
      [
        "javascript:alert(1)",
        "https://evil.example/ada",
        "https://github.com.evil.example/ada",
        "https://github.com",
        "https://github.com/",
        "ftp://github.com/ada",
        "not a link"
      ].each do |url|
        user = build(:user, github_url: url)

        expect(user).not_to be_valid, "expected #{url} to be refused"
        expect(user.errors[:github_url]).to be_present
      end
    end
  end

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

    it "can't make a new account under the minimum age, however it's created" do
      expect(build(:user, date_of_birth: 15.years.ago.to_date)).not_to be_valid
    end

    it "can't be changed once set" do
      user = create(:user, date_of_birth: Date.new(1990, 6, 15))

      expect(user.update(date_of_birth: Date.new(2015, 1, 1))).to be(false)
      expect(user.errors[:date_of_birth]).to include("can't be changed")
      expect(user.reload.date_of_birth).to eq(Date.new(1990, 6, 15))
    end

    it "isn't required to keep using an existing account" do
      user = create(:user)
      user.update_column(:date_of_birth, nil)

      expect(user.reload).to be_valid
    end
  end
end
