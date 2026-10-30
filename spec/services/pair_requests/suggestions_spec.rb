RSpec.describe PairRequests::Suggestions, type: :unit do
  subject(:suggestions) { described_class.call(expired_offer) }

  let(:python) { create(:tag, name: "Python") }
  let(:react) { create(:tag, name: "React") }

  let(:offerer) { create(:user) }
  let(:dead_request) { request_starting_in(2.days, tags: [python]) }
  let(:expired_offer) { create(:offer, offerer:, pair_request: dead_request) }

  def request_starting_in(time, tags: [], **attrs)
    create(:pair_request, with_periods: false, **attrs).tap do |request|
      # Periods can't be created in the past, so place them afterwards.
      create(:period, periodable: request).update_columns(start_at: time.from_now, end_at: time.from_now + 1.hour)
      tags.each { |tag| create(:tagging, taggable: request, tag:) }
    end
  end

  it "ranks requests sharing the dead request's tags above sooner ones" do
    sooner_untagged = request_starting_in(1.hour)
    later_python = request_starting_in(3.days, tags: [python])

    expect(suggestions).to eq([later_python, sooner_untagged])
  end

  it "otherwise suggests the soonest slots, at most three" do
    in_four_days = request_starting_in(4.days)
    in_one_day = request_starting_in(1.day)
    in_three_days = request_starting_in(3.days)
    request_starting_in(5.days)

    expect(suggestions).to eq([in_one_day, in_three_days, in_four_days])
  end

  it "never suggests requests that are off, the offerer's own, or the dead request" do
    request_starting_in(1.day, tags: [python], paused_at: 1.hour.ago)
    request_starting_in(1.day, tags: [python], user: offerer)
    open_request = request_starting_in(2.days)

    expect(suggestions).to eq([open_request])
  end

  it "skips requests the offerer already offered on" do
    already_offered = request_starting_in(1.day, tags: [python])
    create(:offer, offerer:, pair_request: already_offered)
    open_request = request_starting_in(2.days)

    expect(suggestions).to eq([open_request])
  end

  it "skips requests that are already matched or have no upcoming slot" do
    matched = request_starting_in(1.day, tags: [python])
    create(:offer, :accepted, pair_request: matched)
    request_starting_in(-1.day, tags: [python])
    open_request = request_starting_in(2.days)

    expect(suggestions).to eq([open_request])
  end
end
