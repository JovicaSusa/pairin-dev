RSpec.describe PairRequests::BookableSlots, type: :unit do
  subject(:slots) { described_class.call(pair_request) }

  # Monday 19 Oct 2026, 08:00 UTC. Berlin is on summer time (UTC+2) until
  # Sunday 25 Oct, then winter time (UTC+1).
  let(:now) { Time.utc(2026, 10, 19, 8, 0) }
  let(:poster) { create(:user, timezone: "Europe/Berlin") }
  let(:pair_request) { create(:pair_request, user: poster, duration: 45, weekly_hours: false) }

  around { |example| travel_to(now) { example.run } }

  def window(weekday:, from:, to:)
    create(:availability_window, user: poster, weekday:, start_minute: minutes(from), end_minute: minutes(to))
  end

  def minutes(hh_mm)
    hours, mins = hh_mm.split(":").map(&:to_i)
    hours * 60 + mins
  end

  def starts
    slots.map { |slot| slot.start_at.utc }
  end

  it "cuts each window into back-to-back slots of the call length, dropping a slot that would overrun" do
    window(weekday: 2, from: "18:00", to: "20:00")

    expect(starts.first(2)).to eq([Time.utc(2026, 10, 20, 16, 0), Time.utc(2026, 10, 20, 16, 45)])
    expect(slots.first.end_at.utc).to eq(Time.utc(2026, 10, 20, 16, 45))
    expect(starts).not_to include(Time.utc(2026, 10, 20, 17, 30))
  end

  it "reads windows in the poster's timezone, across a daylight-saving change" do
    window(weekday: 2, from: "18:00", to: "18:45")

    expect(starts).to eq([Time.utc(2026, 10, 20, 16, 0), Time.utc(2026, 10, 27, 17, 0)])
  end

  context "on the night clocks go back" do
    # Sunday 25 Oct 2026: 03:00 CEST becomes 02:00 CET (01:00 UTC).
    let(:now) { Time.utc(2026, 10, 20, 8, 0) }

    it "drops the slot that would cross the change" do
      window(weekday: 7, from: "01:00", to: "04:00")

      # 00:30–01:15 UTC would read 02:30–02:15 on the clock.
      expect(starts.select { |start| start < Time.utc(2026, 10, 25, 12) }).to eq([
        Time.utc(2026, 10, 24, 23, 0), Time.utc(2026, 10, 24, 23, 45),
        Time.utc(2026, 10, 25, 1, 15), Time.utc(2026, 10, 25, 2, 0)
      ])
    end
  end

  context "on the night clocks go forward" do
    # Sunday 28 Mar 2027: 02:00 CET becomes 03:00 CEST (01:00 UTC).
    let(:now) { Time.utc(2027, 3, 23, 8, 0) }

    it "drops the slot that would cross the change" do
      window(weekday: 7, from: "01:00", to: "04:00")

      # 00:45–01:30 UTC would read 01:45–03:30 on the clock.
      expect(starts.select { |start| start < Time.utc(2027, 3, 28, 12) }).to eq([Time.utc(2027, 3, 28, 0, 0)])
    end
  end

  it "only looks 14 days ahead" do
    window(weekday: 1, from: "18:00", to: "18:45")

    # Today's (19 Oct) and the next Monday's slots; 2 Nov is 14 days out.
    expect(starts).to eq([Time.utc(2026, 10, 19, 16, 0), Time.utc(2026, 10, 26, 17, 0)])
  end

  it "needs at least 3 hours' notice" do
    window(weekday: 1, from: "12:30", to: "14:00")

    # 12:30 Berlin is 10:30 UTC, 2.5h away; 13:15 Berlin is 11:15 UTC, 3.25h away.
    expect(starts.first).to eq(Time.utc(2026, 10, 19, 11, 15))
  end

  it "handles a window that runs to midnight" do
    window(weekday: 2, from: "23:00", to: "24:00")

    expect(starts.first).to eq(Time.utc(2026, 10, 20, 21, 0))
    expect(slots.first.end_at.utc).to eq(Time.utc(2026, 10, 20, 21, 45))
  end

  it "hides slots overlapping any accepted session of the poster, on any of their requests" do
    window(weekday: 2, from: "18:00", to: "20:00")
    other_request = create(:pair_request, user: poster, weekly_hours: false)
    session = create(:session, sessionable: other_request, start_at: Time.utc(2026, 10, 20, 16, 30), end_at: Time.utc(2026, 10, 20, 17, 0))

    expect(session.participants).to include(poster)
    expect(starts).to eq([Time.utc(2026, 10, 27, 17, 0), Time.utc(2026, 10, 27, 17, 45)])
  end

  it "keeps a slot that only touches a session" do
    window(weekday: 2, from: "18:00", to: "18:45")
    create(:session, sessionable: create(:pair_request, user: poster, weekly_hours: false),
      start_at: Time.utc(2026, 10, 20, 16, 45), end_at: Time.utc(2026, 10, 20, 17, 30))

    expect(starts.first).to eq(Time.utc(2026, 10, 20, 16, 0))
  end

  it "has no slots without weekly hours" do
    expect(slots).to be_empty
  end

  it "has no slots when the call is longer than every window" do
    window(weekday: 2, from: "18:00", to: "18:30")

    expect(slots).to be_empty
  end
end
