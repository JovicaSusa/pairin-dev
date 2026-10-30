RSpec.describe PairRequests::Suggestions, type: :unit do
  subject(:suggestions) { described_class.call(expired_offer) }

  let(:python) { create(:tag, name: "Python") }
  let(:react) { create(:tag, name: "React") }

  let(:offerer) { create(:user) }
  let(:dead_request) { request_starting_in(2.days, tags: [python]) }
  let(:expired_offer) { create(:offer, offerer:, pair_request: dead_request) }

  # Monday 2 Nov 2026, 08:00 UTC.
  around { |example| travel_to(Time.utc(2026, 11, 2, 8, 0)) { example.run } }

  # A one-hour request whose poster is free for one hour a week, starting
  # `time` from now; so its next bookable slot is then.
  def request_starting_in(time, tags: [], **attrs)
    start = time.from_now.utc
    poster = attrs.delete(:user) || create(:user)
    create(:availability_window, user: poster, weekday: start.to_date.cwday,
      start_minute: start.hour * 60 + start.min, end_minute: start.hour * 60 + start.min + 60)

    create(:pair_request, user: poster, duration: 60, **attrs).tap do |request|
      tags.each { |tag| create(:tagging, taggable: request, tag:) }
    end
  end

  it "ranks requests sharing the dead request's tags above sooner ones" do
    sooner_untagged = request_starting_in(4.hours)
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
    create(:pair_request, weekly_hours: false).tap { |request| create(:tagging, taggable: request, tag: python) }
    open_request = request_starting_in(2.days)

    expect(suggestions).to eq([open_request])
  end
end
