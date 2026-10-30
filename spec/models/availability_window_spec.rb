RSpec.describe AvailabilityWindow, type: :model do
  let(:user) { create(:user) }

  def window(**attrs)
    described_class.new(user:, weekday: 2, start_minute: 18 * 60, end_minute: 20 * 60, **attrs)
  end

  it "is valid for a weekday with an end after its start" do
    expect(window).to be_valid
  end

  it "rejects an end at or before the start" do
    expect(window(end_minute: 18 * 60)).not_to be_valid
    expect(window(end_minute: 17 * 60).tap(&:validate).errors.attribute_names).to include(:end_minute)
  end

  it "keeps times within a single day" do
    expect(window(start_minute: -30)).not_to be_valid
    expect(window(end_minute: 24 * 60 + 30)).not_to be_valid
    expect(window(start_minute: 23 * 60, end_minute: 24 * 60)).to be_valid
  end

  it "doesn't overlap another window on the same day" do
    window.save!

    expect(window(start_minute: 19 * 60, end_minute: 21 * 60)).not_to be_valid
    expect(window(start_minute: 18 * 60, end_minute: 20 * 60)).not_to be_valid
    expect(window(start_minute: 20 * 60, end_minute: 21 * 60)).to be_valid
    expect(window(weekday: 3)).to be_valid
    expect(described_class.new(user: create(:user), weekday: 2, start_minute: 18 * 60, end_minute: 20 * 60)).to be_valid
  end

  it "only accepts Monday (1) to Sunday (7)" do
    expect(window(weekday: 0)).not_to be_valid
    expect(window(weekday: 8)).not_to be_valid
    expect(window(weekday: 7)).to be_valid
  end
end
