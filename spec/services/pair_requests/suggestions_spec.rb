RSpec.describe PairRequests::Suggestions, type: :unit do
  subject(:suggestions) { described_class.call(expired_offer) }

  let(:python) { create(:tag, name: "Python") }

  let(:offerer) { create(:user) }
  let(:dead_request) { request_posted(9.days.ago, tags: [python]) }
  let(:expired_offer) { create(:offer, offerer:, pair_request: dead_request) }

  def request_posted(time, tags: [], **attrs)
    create(:pair_request, created_at: time, **attrs).tap do |request|
      tags.each { |tag| create(:tagging, taggable: request, tag:) }
    end
  end

  it "ranks requests sharing the dead request's tags above newer ones" do
    newer_untagged = request_posted(1.hour.ago)
    older_python = request_posted(3.days.ago, tags: [python])

    expect(suggestions).to eq([older_python, newer_untagged])
  end

  it "otherwise suggests the newest, at most three" do
    four_days = request_posted(4.days.ago)
    one_day = request_posted(1.day.ago)
    three_days = request_posted(3.days.ago)
    request_posted(5.days.ago)

    expect(suggestions).to eq([one_day, three_days, four_days])
  end

  it "suggests a poster with no weekly hours" do
    request = request_posted(1.day.ago)

    expect(request.user.availability_windows).to be_empty
    expect(suggestions).to eq([request])
  end

  it "never suggests requests that are off, the offerer's own, or the dead request" do
    request_posted(1.day.ago, tags: [python], paused_at: 1.hour.ago)
    request_posted(1.day.ago, tags: [python], user: offerer)
    open_request = request_posted(2.days.ago)

    expect(suggestions).to eq([open_request])
  end

  it "skips requests the offerer already offered on" do
    already_offered = request_posted(1.day.ago, tags: [python])
    create(:offer, offerer:, pair_request: already_offered)
    open_request = request_posted(2.days.ago)

    expect(suggestions).to eq([open_request])
  end

  it "skips requests that are already matched" do
    matched = request_posted(1.day.ago, tags: [python])
    create(:offer, :accepted, pair_request: matched)
    open_request = request_posted(2.days.ago)

    expect(suggestions).to eq([open_request])
  end
end
