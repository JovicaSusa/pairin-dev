RSpec.describe Session, type: :model do
  describe "scopes" do
    describe ".future" do
      subject(:future) { described_class.future }

      let(:past_session) { create(:session, start_at: 1.minute.ago) }
      let(:future_session) { create(:session, start_at: 1.minute.from_now) }

      it { is_expected.to contain_exactly(future_session) }
    end
  end

  describe "validations" do
    describe "dates in order" do
      let(:session) { build(:session, start_at: 30.minutes.from_now, end_at: 29.minutes.from_now) }

      it "sets expected error" do
        expect(session.valid?).to be false
        expect(session.errors[:end_at]).to contain_exactly("must be after start date")
      end
    end

    describe "dates in future" do
      let(:session) { build(:session, start_at: 40.minutes.ago, end_at: 10.minutes.ago) }

      it "sets expected error" do
        expect(session.valid?).to be false
        expect(session.errors[:end_at]).to contain_exactly("must be in future")
        expect(session.errors[:start_at]).to contain_exactly("must be in future")
      end
    end
  end

  describe "holder" do
    subject(:holder) { session.holder }

    let(:session) { build(:session) }
    let(:session) { build(:session, sessionable: pair_request) }
    let(:pair_request) { build(:pair_request, user: holder) }
    let(:holder) { build(:user) }

    it { is_expected.to eq holder }
  end

  describe "hold_by_user?" do
    subject(:hold_by_user?) { session.hold_by_user?(user) }

    let(:user) { build(:user) }
    let(:session) { build(:session, sessionable: pair_request) }
    let(:pair_request) { build(:pair_request, user: holder) }

    context "when hold by given user" do
      let(:holder) { user }

      it { is_expected.to be true }
    end

    context "when hold by other user" do
      let(:holder) { build(:user) }

      it { is_expected.to be false }
    end
  end

  describe "#other_participant" do
    subject(:other_participant) { session.other_participant(participant) }

    let(:session) { create(:session, with_holder: false, with_partner: false) }
    let(:participant_1) { create(:user) }
    let(:participant_2) { create(:user) }
    let!(:participation_1) { create(:participation, participable: session, participant: participant_1) }
    let!(:participation_2) { create(:participation, participable: session, participant: participant_2) }

    context "when participant_1 given" do
      let(:participant) { participant_1 }

      it { is_expected.to eq(participant_2) }
    end

    context "when participant_2 given" do
      let(:participant) { participant_2 }

      it { is_expected.to eq(participant_1) }
    end
  end
end
