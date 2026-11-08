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

  describe "answering and cancelling" do
    let(:other) { partnership.offer.other_person(proposer) }
    let(:outsider) { create(:user) }

    def start!(at)
      session.update_columns(start_at: at, end_at: at + 1.hour)
    end

    describe "#confirm! and #decline!" do
      it "lets the partner who didn't propose it answer" do
        expect(session.confirm!(by: other)).to be(true)
        expect(session.reload).to be_confirmed

        declined = create(:session, partnership:, proposed_by: proposer)
        expect(declined.decline!(by: other)).to be(true)
        expect(declined.reload).to be_declined
      end

      it "doesn't let the proposer or anyone else answer" do
        expect(session.confirm!(by: proposer)).to be(false)
        expect(session.decline!(by: proposer)).to be(false)
        expect(session.confirm!(by: outsider)).to be(false)
        expect(session.reload).to be_proposed
      end

      it "can't answer a proposal that has expired" do
        start!(1.hour.ago)

        expect(session.confirm!(by: other)).to be(false)
        expect(session.decline!(by: other)).to be(false)
        expect(session.reload).to be_proposed
      end

      it "can't answer twice, or answer a withdrawn proposal" do
        session.decline!(by: other)
        expect(session.confirm!(by: other)).to be(false)

        withdrawn = create(:session, partnership:, proposed_by: proposer)
        withdrawn.cancel!(by: proposer)
        expect(withdrawn.confirm!(by: other)).to be(false)
        expect(withdrawn.reload).to be_cancelled
      end
    end

    describe "#cancel!" do
      it "lets the proposer withdraw a proposal, but not the other partner" do
        expect(session.cancel!(by: other)).to be(false)
        expect(session.reload).to be_proposed

        expect(session.cancel!(by: proposer)).to be(true)
        expect(session.reload).to have_attributes(status: "cancelled", cancelled_by: proposer)
      end

      it "lets either partner cancel a confirmed session before it starts" do
        session.confirm!(by: other)
        expect(session.cancel!(by: other)).to be(true)
        expect(session.reload).to have_attributes(status: "cancelled", cancelled_by: other)

        mine = create(:session, partnership:, proposed_by: proposer)
        mine.confirm!(by: other)
        expect(mine.cancel!(by: proposer)).to be(true)
      end

      it "can't cancel once it has started, or for someone outside the partnership" do
        session.confirm!(by: other)
        expect(session.cancel!(by: outsider)).to be(false)

        start!(10.minutes.ago)
        expect(session.cancel!(by: other)).to be(false)
        expect(session.reload).to be_confirmed
      end

      it "can't cancel a declined session" do
        session.decline!(by: other)

        expect(session.cancel!(by: proposer)).to be(false)
        expect(session.reload).to be_declined
      end
    end

    it "does nothing once the partnership has ended" do
      confirmed = create(:session, partnership:, proposed_by: proposer)
      confirmed.confirm!(by: other)
      partnership.update_columns(ended_at: Time.current)

      expect(session.reload.confirm!(by: other)).to be(false)
      expect(session.cancel!(by: proposer)).to be(false)
      expect(confirmed.reload.cancel!(by: other)).to be(false)
    end
  end

  describe "ending the partnership" do
    include ActiveJob::TestHelper

    let(:other) { partnership.offer.other_person(proposer) }

    it "cancels its future sessions without emailing about them" do
      confirmed = create(:session, partnership:, proposed_by: proposer, start_at: 3.days.from_now.change(min: 0))
      confirmed.confirm!(by: other)
      declined = create(:session, partnership:, proposed_by: proposer)
      declined.decline!(by: other)
      done = create(:session, partnership:, proposed_by: proposer, status: "confirmed")
      done.update_columns(start_at: 2.days.ago, end_at: 2.days.ago + 1.hour)

      expect { partnership.end!(by: other) }.not_to have_enqueued_mail(SessionMailer)

      # Nobody in particular cancelled these, so the page can say why.
      expect(session.reload).to have_attributes(status: "cancelled", cancelled_by: nil)
      expect(confirmed.reload).to have_attributes(status: "cancelled", cancelled_by: nil)
      expect(declined.reload).to be_declined
      expect(done.reload).to be_confirmed
    end
  end
end
