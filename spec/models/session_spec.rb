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
end
