RSpec.describe SessionFeedback, type: :model do
  describe "validations" do
    describe "went_well" do
      let(:session_feedback) { build(:session_feedback) }

      it "allows nil" do
        session_feedback.went_well = nil

        expect(session_feedback).to be_valid
      end

      it "allows values in the allowed set" do
        session_feedback.went_well = "great"

        expect(session_feedback).to be_valid
      end

      it "rejects values outside the allowed set" do
        session_feedback.went_well = "amazing"

        expect(session_feedback).to be_invalid
        expect(session_feedback.errors[:went_well]).to be_present
      end
    end

    describe "participant_id uniqueness scoped to session_id" do
      let(:session) { create(:session) }
      let(:participant) { create(:user) }

      before { create(:session_feedback, session:, participant:) }

      it "rejects a second feedback from the same participant for the same session" do
        duplicate = build(:session_feedback, session:, participant:)

        expect(duplicate).to be_invalid
        expect(duplicate.errors[:participant_id]).to be_present
      end

      it "allows the same participant to leave feedback for a different session" do
        other_session = create(:session)
        other_feedback = build(:session_feedback, session: other_session, participant:)

        expect(other_feedback).to be_valid
      end
    end
  end
end
