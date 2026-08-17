RSpec.describe "display session summaries", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "when a completed session has feedback from both participants, shared publicly" do
    let!(:session) { create(:session, :past) }
    let(:pair_request) { session.sessionable }
    let(:participant_1) { session.participants.first }
    let(:participant_2) { session.participants.second }

    before do
      pair_request.update!(subject: "Refactor the payments module", goal: "Learn TDD", platform: "zoom")
      participant_1.update!(name: "Alex Morgan")
      participant_2.update!(name: "Jamie Lee")
      create(:session_feedback, :shared_publicly, session:, participant: participant_1, went_well: "great", learned: "Extract method")
      create(:session_feedback, :shared_publicly, session:, participant: participant_2, went_well: "tough", learned: "Merge conflicts are hard")
    end

    it "shows the pair request details and both participants' retros side by side" do
      visit session_summaries_path

      expect(page).to have_content("Refactor the payments module")
      expect(page).to have_content("Learn TDD")
      expect(page).to have_content("zoom")
      expect(page).to have_content(participant_1.name)
      expect(page).to have_content("Extract method")
      expect(page).to have_content(participant_2.name)
      expect(page).to have_content("Merge conflicts are hard")
    end
  end

  context "when only one participant has shared their retro publicly" do
    let!(:session) { create(:session, :past) }
    let(:pair_request) { session.sessionable }
    let(:participant_1) { session.participants.first }
    let(:participant_2) { session.participants.second }

    before do
      pair_request.update!(subject: "Debug the flaky spec")
      participant_1.update!(name: "Sam Rivera")
      participant_2.update!(name: "Priya Patel")
      create(:session_feedback, :shared_publicly, session:, participant: participant_1, went_well: "good", learned: "Timing issue")
      create(:session_feedback, session:, participant: participant_2, went_well: "tough", learned: "Kept this one private")
    end

    it "renders only the retro that was shared publicly" do
      visit session_summaries_path

      expect(page).to have_content("Debug the flaky spec")
      expect(page).to have_content(participant_1.name)
      expect(page).to have_content("Timing issue")
      expect(page).not_to have_content(participant_2.name)
      expect(page).not_to have_content("Kept this one private")
    end
  end

  context "when feedback exists but nobody has shared it publicly" do
    let!(:session) { create(:session, :past) }
    let(:pair_request) { session.sessionable }
    let(:participant_1) { session.participants.first }

    before do
      pair_request.update!(subject: "Pair on the auth flow")
      create(:session_feedback, session:, participant: participant_1, went_well: "okay", learned: "Should stay hidden")
    end

    it "still shows the pair request but no retro content" do
      visit session_summaries_path

      expect(page).to have_content("Pair on the auth flow")
      expect(page).not_to have_content("Should stay hidden")
    end
  end

  context "when the current user is not a participant of the session" do
    let!(:session) { create(:session, :past, with_holder: false, with_partner: false) }

    before { session.sessionable.update!(subject: "Someone else's session") }

    it "is still reachable and shows the summary" do
      visit session_summaries_path

      expect(page).to have_content("Someone else's session")
    end
  end

  context "when no sessions have ended yet" do
    let!(:upcoming_session) { create(:session) }

    it "shows an empty state" do
      visit session_summaries_path

      expect(page).to have_content("No session summaries yet")
    end
  end
end
