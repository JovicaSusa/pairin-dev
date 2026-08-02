RSpec.describe "submit session feedback", type: :system do
  let(:current_user) { create(:user) }
  let(:session) { create(:session) }

  before { sign_in(current_user) }

  context "when current user is a participant" do
    let(:session) { create(:session, with_holder: false) }
    let!(:participation) { create(:participation, participable: session, participant: current_user) }

    it "creates a session feedback for the current user" do
      visit new_session_feedback_path(session_id: session.id)

      click_button "Great"
      fill_in "What did you learn?", with: "Learned a ton about pairing"

      click_button "Submit retro"

      expect(page).to have_content("Thanks for sharing your retro!")

      feedback = session.session_feedbacks.find_by!(participant: current_user)
      expect(feedback.went_well).to eq("great")
      expect(feedback.learned).to eq("Learned a ton about pairing")
    end

    it "allows submitting without picking a reaction" do
      visit new_session_feedback_path(session_id: session.id)

      fill_in "Notes", with: "No strong reaction, just some notes"
      click_button "Submit retro"

      expect(page).to have_content("Thanks for sharing your retro!")

      feedback = session.session_feedbacks.find_by!(participant: current_user)
      expect(feedback.went_well).to be_blank
      expect(feedback.notes).to eq("No strong reaction, just some notes")
    end

    context "when feedback was already submitted for this session" do
      let!(:existing_feedback) { create(:session_feedback, session: session, participant: current_user) }

      it "rejects the duplicate submission cleanly" do
        visit new_session_feedback_path(session_id: session.id)

        click_button "Good"
        click_button "Submit retro"

        expect(page).to have_content("already submitted feedback")
        expect(session.session_feedbacks.where(participant: current_user).count).to eq(1)
      end
    end
  end

  context "when current user is not a participant of the session" do
    it "is not authorized" do
      visit new_session_feedback_path(session_id: session.id)

      expect(page).to have_content("Not authorized for this action")
    end
  end
end
