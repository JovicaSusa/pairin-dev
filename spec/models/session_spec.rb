require "rails_helper"

RSpec.describe Session do
  let(:session) { create(:session) }
  let(:partnership) { session.partnership }
  let(:proposer) { partnership.offer.offerer }

  def propose(date: 2.days.from_now.to_date.iso8601, time: "18:00", minutes: "60", call_link: nil, by: proposer)
    described_class.propose(partnership:, by:, date:, time:, minutes:, call_link:)
  end

  describe ".propose" do
    it "reads the date and time in the proposer's own timezone" do
      proposer.update!(timezone: "Asia/Kolkata")

      proposal = propose(date: "2030-03-04", time: "18:30", minutes: "90")

      expect(proposal.start_at).to eq(Time.utc(2030, 3, 4, 13, 0))
      expect(proposal.end_at).to eq(Time.utc(2030, 3, 4, 14, 30))
      expect(proposal.minutes).to eq(90)
      expect(propose(date: "2030-03-04", time: "18:30:00").start_at).to eq(Time.utc(2030, 3, 4, 13, 0))
      expect(proposal).to be_valid
      expect(proposal).to be_proposed
    end

    it "leaves out what doesn't parse, so validation says what's missing" do
      expect(propose(time: "").tap(&:validate).errors[:start_at]).to include("can't be blank")
      expect(propose(date: "not a date").tap(&:validate).errors[:start_at]).to include("can't be blank")
      expect(propose(time: "25:99").tap(&:validate).errors[:start_at]).to include("can't be blank")
      expect(propose(minutes: "lots").tap(&:validate).errors[:end_at]).to include("can't be blank")
    end
  end

  it "can't start in the past" do
    expect(propose(date: Date.yesterday.iso8601).tap(&:validate).errors[:start_at]).to include("must be in the future")
  end

  it "only takes the lengths offered" do
    expect(propose(minutes: "60")).to be_valid
    expect(propose(minutes: "61").tap(&:validate).errors[:end_at]).to include("must be one of the lengths offered")
    expect(propose(minutes: "0").tap(&:validate).errors[:end_at]).to include("must be one of the lengths offered")
  end

  describe "the call link" do
    it "is optional" do
      expect(propose(call_link: "  ")).to be_valid
      expect(propose(call_link: "  ").call_link).to be_nil
    end

    it "only takes web links" do
      expect(propose(call_link: "https://meet.google.com/abc-defg-hij")).to be_valid
      expect(propose(call_link: "javascript:alert(1)").tap(&:validate).errors[:call_link]).to include("must start with http:// or https://")
      expect(propose(call_link: "meet.google.com/abc").tap(&:validate).errors[:call_link]).to include("must start with http:// or https://")
      expect(propose(call_link: "https://exa mple.com").tap(&:validate).errors[:call_link]).to include("isn't a valid link")
    end
  end

  it "expires when nobody answers before it starts" do
    session.update_columns(start_at: 1.hour.ago, end_at: 1.hour.from_now)

    expect(session).to be_expired
    session.update_columns(status: "confirmed")
    expect(session).not_to be_expired
  end

  it "goes with the partnership" do
    session

    expect { partnership.destroy! }.to change(described_class, :count).by(-1)
  end

  describe "answering" do
    let(:other) { partnership.offer.other_person(proposer) }
    let(:outsider) { create(:user) }

    it "lets only the partner who didn't propose it confirm or decline it" do
      expect(session.confirm!(by: proposer)).to be(false)
      expect(session.confirm!(by: outsider)).to be(false)
      expect(session.reload).to be_proposed

      expect(session.confirm!(by: other)).to be(true)
      expect(session.reload).to be_confirmed
    end

    it "lets the other partner decline it" do
      expect(session.decline!(by: proposer)).to be(false)
      expect(session.decline!(by: other)).to be(true)
      expect(session.reload).to be_declined
    end

    it "lets only the proposer withdraw it" do
      expect(session.withdraw!(by: other)).to be(false)
      expect(session.withdraw!(by: proposer)).to be(true)
      expect(session.reload).to be_withdrawn
    end

    it "takes only one answer" do
      session.decline!(by: other)

      expect(session.confirm!(by: other)).to be(false)
      expect(session.withdraw!(by: proposer)).to be(false)
      expect(session.reload).to be_declined
    end

    it "can't confirm an expired proposal" do
      session.update_columns(start_at: 1.minute.ago, end_at: 59.minutes.from_now)

      expect(session.confirm!(by: other)).to be(false)
      expect(session.decline!(by: other)).to be(false)
      expect(session.withdraw!(by: proposer)).to be(false)
      expect(session.reload).to be_expired
    end

    it "can't answer once the partnership has ended" do
      partnership.update_columns(ended_at: Time.current, ended_by_id: proposer.id)

      expect(session.confirm!(by: other)).to be(false)
    end
  end

  describe "cancelling" do
    let(:other) { partnership.offer.other_person(proposer) }

    before { session.confirm!(by: other) }

    it "lets either partner cancel a confirmed session before it starts, and remembers who" do
      expect(session.cancel!(by: create(:user))).to be(false)

      expect(session.cancel!(by: proposer)).to be(true)
      expect(session.reload).to have_attributes(status: "cancelled", cancelled_by: proposer)
    end

    it "works for the partner who confirmed it too" do
      expect(session.cancel!(by: other)).to be(true)
      expect(session.reload.cancelled_by).to eq(other)
    end

    it "can't cancel one that has started" do
      session.update_columns(start_at: 1.minute.ago, end_at: 59.minutes.from_now)

      expect(session.cancel!(by: proposer)).to be(false)
      expect(session.reload).to be_confirmed
    end

    it "can't cancel one that was only proposed" do
      proposal = create(:session, partnership:, proposed_by: proposer, start_at: 3.days.from_now.change(min: 0))

      expect(proposal.cancel!(by: other)).to be(false)
    end
  end

  describe "when the partnership ends" do
    it "cancels the sessions still ahead, without saying who" do
      other = partnership.offer.other_person(proposer)
      confirmed = create(:session, partnership:, proposed_by: proposer, start_at: 3.days.from_now.change(min: 0))
      confirmed.confirm!(by: other)
      done = create(:session, partnership:, proposed_by: proposer, start_at: 4.days.from_now.change(min: 0))
      done.confirm!(by: other)
      done.update_columns(start_at: 2.days.ago, end_at: 2.days.ago + 1.hour)
      declined = create(:session, partnership:, proposed_by: proposer, start_at: 5.days.from_now.change(min: 0))
      declined.decline!(by: other)
      under_way = create(:session, partnership:, proposed_by: proposer, start_at: 6.days.from_now.change(min: 0))
      under_way.confirm!(by: other)
      under_way.update_columns(start_at: 10.minutes.ago, end_at: 50.minutes.from_now)

      partnership.end!(by: other)

      expect(session.reload).to have_attributes(status: "cancelled", cancelled_by: nil)
      expect(confirmed.reload).to have_attributes(status: "cancelled", cancelled_by: nil)
      expect(done.reload).to be_confirmed
      expect(declined.reload).to be_declined
      # Already started, so it may well be happening: left as it was.
      expect(under_way.reload).to be_confirmed
    end
  end
end
