RSpec.describe "workspaces", type: :system do
  let(:poster) { create(:user, name: "Maya") }
  let(:partner) { create(:user, name: "Sam") }
  let(:search) { create(:pair_request, user: poster, subject: "Python buddy", commitment: "open_ended") }
  let!(:offer) { create(:offer, pair_request: search, offerer: partner, goal: "Finish the course", how_long: "few_weeks", message: "Hi Maya") }

  before do
    offer.post_message(poster, "Great to meet you")
    offer.propose_partnership!(by: partner)
  end

  it "opens from accepting a proposal, and works as a dashboard" do
    sign_in(poster)
    visit conversation_path(offer)

    click_button "Accept"

    expect(page).to have_content("You and Sam")
    expect(page).to have_content(/working towards/i)
    expect(page).to have_content("Finish the course")
    expect(page).to have_content("Open-ended")
    expect(page).to have_content("A few weeks")
    expect(page).to have_content("Hi Maya")

    fill_in "Write a message", with: "Let's start Tuesday"
    click_button "Send"

    expect(page).to have_content("Let's start Tuesday")
    expect(page).to have_content("You and Sam")
  end

  context "with a partnership" do
    before do
      offer.accept_proposal!(by: poster)
      sign_in(poster)
    end

    it "is reached from the Partners page" do
      visit pair_requests_path

      click_link "Partners"
      click_link "Sam"

      expect(page).to have_content("You and Sam")
    end

    it "edits and clears the goal, and adds one back" do
      visit partner_path(Partnership.last)

      click_button "Edit"
      fill_in "What are you working towards? (optional)", with: "Build a scraper"
      click_button "Save goal"
      expect(page).to have_content("Build a scraper")

      click_button "Edit"
      fill_in "What are you working towards? (optional)", with: ""
      click_button "Save goal"
      expect(page).to have_button("Add a shared goal (optional)")
      expect(page).not_to have_content(/working towards/i)

      click_button "Add a shared goal (optional)"
      fill_in "What are you working towards? (optional)", with: "Ship it"
      click_button "Save goal"
      expect(page).to have_content("Ship it")
    end

    it "blocks after asking, then reads as ended" do
      visit partner_path(Partnership.last)

      click_button "Block"
      within('[aria-label="Confirm block"]') { click_button "Block" }

      expect(page).to have_content("You ended this partnership.")
      expect(page).not_to have_field("Write a message")
      expect(page).not_to have_button("Edit")
    end

    it "ends after asking, and reads as ended" do
      visit partner_path(Partnership.last)

      click_button "End partnership"
      expect(page).to have_content("We'll tell Sam kindly.")
      click_button "Keep going"
      expect(Partnership.last).not_to be_ended

      click_button "End partnership"
      fill_in "Why? (optional, only we see this)", with: "Different goals"
      within("form", text: "End this partnership?") { click_button "End partnership" }

      expect(page).to have_content("You ended this partnership.")
      expect(page).not_to have_field("Write a message")
      expect(page).not_to have_button("End partnership")
      expect(Partnership.last.end_reason).to eq("Different goals")
    end

    it "shows when the next check-in goes out, then a marker for each week" do
      visit partner_path(Partnership.last)
      expect(page).to have_content("The next check-in email goes out on")
      expect(page).not_to have_content("W1")

      partnership = Partnership.last
      travel 7.days + 1.minute do
        CheckIn.create!(partnership:, user: partner, week: 1).answer!(true)
        visit partner_path(partnership)

        expect(page).to have_content("W1")
        expect(page).to have_css('li[title="Week 1: you worked together"]')
      end
    end

    it "links to the Workspace from the conversation" do
      visit conversation_path(offer)

      click_link "Open your Workspace"

      expect(page).to have_content("You and Sam")
    end
  end
end
