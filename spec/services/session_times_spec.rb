require "rails_helper"

RSpec.describe SessionTimes do
  let(:me) { create(:user, name: "Maya", timezone: "Europe/Berlin") }
  let(:partner) { create(:user, name: "Sam", timezone: "America/New_York") }
  let(:partnership) do
    offer = create(:offer, pair_request: create(:pair_request, user: me), offerer: partner)
    offer.post_message(me, "Hi")
    offer.propose_partnership!(by: partner)
    offer.accept_proposal!(by: me)
  end
  # Monday 4 March 2030, 09:00 in Berlin, 03:00 in New York.
  let(:now) { Time.utc(2030, 3, 4, 8, 0) }

  def window(user, weekday, from, to)
    hour = ->(text) { h, m = text.split(":").map(&:to_i); (h * 60) + m }
    create(:availability_window, user:, weekday:, start_minute: hour.(from), end_minute: hour.(to))
  end

  def times(at: now) = described_class.new(partnership, viewer: me, now: at)
  def suggested(minutes, at: now) = times(at:).suggestions(minutes)

  it "suggests the start of each overlap, across timezones, if the session fits" do
    window(me, 1, "18:00", "21:00")      # 17:00–20:00 UTC
    window(partner, 1, "13:00", "14:00") # 18:00–19:00 UTC

    expect(suggested(60)).to eq([Time.utc(2030, 3, 4, 18, 0)])
    expect(suggested(90)).to be_empty
  end

  it "follows a daylight-saving change in one timezone" do
    window(me, 1, "18:00", "21:00")
    window(partner, 1, "13:00", "14:00") # New York moves to EDT on 10 March: 17:00–18:00 UTC

    expect(suggested(60, at: Time.utc(2030, 3, 8, 8, 0))).to eq([Time.utc(2030, 3, 11, 17, 0)])
  end

  it "treats hours that run on past midnight as one stretch" do
    partner.update_columns(timezone: "Europe/Berlin")
    [me, partner].each do |user|
      window(user, 1, "22:00", "24:00")
      window(user, 2, "00:00", "01:00")
    end

    expect(suggested(120)).to eq([Time.utc(2030, 3, 4, 21, 0)])
  end

  it "skips anything less than an hour away, and looks only a week ahead" do
    window(me, 1, "18:00", "21:00")
    window(partner, 1, "13:00", "14:00")

    # Today's starts 30 minutes from now: what's left of it from an hour on is
    # offered (on the quarter hour) if the session fits, then next week's (EDT by then).
    expect(suggested(15, at: Time.utc(2030, 3, 4, 17, 25))).to eq([Time.utc(2030, 3, 4, 18, 30), Time.utc(2030, 3, 11, 17, 0)])
    expect(suggested(60, at: Time.utc(2030, 3, 4, 17, 25))).to eq([Time.utc(2030, 3, 11, 17, 0)])
    # And next week's is just over a week away from here.
    expect(suggested(15, at: Time.utc(2030, 3, 4, 16, 59))).to eq([Time.utc(2030, 3, 4, 18, 0)])
  end

  it "works around confirmed sessions" do
    window(me, 1, "18:00", "21:00")
    window(partner, 1, "13:00", "14:00")
    create(:session, partnership:, proposed_by: me, status: "confirmed", start_at: Time.utc(2030, 3, 4, 18, 0), end_at: Time.utc(2030, 3, 4, 18, 30))
    create(:session, partnership:, proposed_by: me, start_at: Time.utc(2030, 3, 4, 18, 30), end_at: Time.utc(2030, 3, 4, 19, 0))

    expect(suggested(30)).to eq([Time.utc(2030, 3, 4, 18, 30)])
    expect(suggested(60)).to be_empty
  end

  it "works around the viewer's confirmed sessions with other partners too" do
    window(me, 1, "18:00", "21:00")
    window(partner, 1, "13:00", "14:00")
    other = create(:offer, pair_request: create(:pair_request, user: me))
    other.post_message(me, "Hi")
    other.propose_partnership!(by: other.offerer)
    elsewhere = other.accept_proposal!(by: me)
    create(:session, partnership: elsewhere, proposed_by: me, status: "confirmed", start_at: Time.utc(2030, 3, 4, 18, 0), end_at: Time.utc(2030, 3, 4, 18, 30))

    expect(suggested(30)).to eq([Time.utc(2030, 3, 4, 18, 30)])
  end

  it "gives at most six, soonest first" do
    partner.update_columns(timezone: "Europe/Berlin")
    (1..7).each do |day|
      window(me, day, "18:00", "20:00")
      window(partner, day, "18:00", "20:00")
    end

    expect(suggested(60).size).to eq(6)
    expect(suggested(60)).to eq(suggested(60).sort)
    expect(suggested(60).first).to eq(Time.utc(2030, 3, 4, 17, 0))
  end

  it "has nothing to suggest when either has no hours" do
    window(me, 1, "18:00", "21:00")

    expect(suggested(15)).to be_empty
  end

  describe "#to_props" do
    it "leaves out an under-18 partner's hours, which would hint at where they are" do
      partnership
      partner.update_columns(date_of_birth: 17.years.ago.to_date)
      window(partner, 1, "13:00", "14:00")

      fresh = described_class.new(Partnership.find(partnership.id), viewer: me, now:)
      expect(fresh.to_props[:partner_hours]).to be_nil
    end

    it "shows hours under way from their real start, not from now" do
      window(me, 1, "18:00", "20:00")

      props = times(at: Time.utc(2030, 3, 4, 17, 37)).to_props

      expect(props[:my_hours].first).to eq(["2030-03-04T17:00:00Z", "2030-03-04T19:00:00Z"])
    end

    it "has the suggestions for every length, and both people's hours, in UTC" do
      window(me, 1, "18:00", "20:00")
      window(me, 1, "20:00", "21:00")
      window(partner, 1, "13:00", "14:00")

      props = times.to_props

      expect(props[:suggestions].keys).to eq(Session::LENGTHS)
      expect(props[:suggestions][60]).to eq(["2030-03-04T18:00:00Z"])
      expect(props[:my_hours].first).to eq(["2030-03-04T17:00:00Z", "2030-03-04T20:00:00Z"])
      expect(props[:partner_hours].first).to eq(["2030-03-04T18:00:00Z", "2030-03-04T19:00:00Z"])
      # Far enough ahead to say whether a later proposal is in the partner's hours.
      expect(props[:partner_hours].size).to eq(4)
    end
  end
end
