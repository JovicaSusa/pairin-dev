RSpec.describe "workspaces", type: :system do
  let(:poster) { create(:user, name: "Maya") }
  let(:partner) { create(:user, name: "Sam") }
  let(:search) { create(:pair_request, user: poster, subject: "Python buddy", commitment: "open_ended") }
  let!(:offer) { create(:offer, pair_request: search, offerer: partner, goal: "Finish the course", how_long: "few_weeks", message: "Hi Maya") }

  before do
    offer.post_message(poster, "Great to meet you")
    offer.propose_partnership!(by: partner)
  end

  it "opens from accepting a proposal on an overview, with the chat a tap away" do
    sign_in(poster)
    visit conversation_path(offer)

    click_button "Accept"

    expect(page).to have_content("You and Sam")
    expect(page).to have_content(/working towards/i)
    expect(page).to have_content("Finish the course")
    expect(page).to have_content("Open-ended")
    expect(page).to have_content("A few weeks")
    expect(page).not_to have_field("Write a message")

    click_link "Open chat"

    expect(page).to have_content("Chat with Sam")
    expect(page).to have_content("Hi Maya")

    fill_in "Write a message", with: "Let's start Tuesday"
    click_button "Send"

    expect(page).to have_content("Let's start Tuesday")
    expect(page).to have_content("Chat with Sam")

    click_link "Overview"

    expect(page).to have_content("You: Let's start Tuesday")
  end

  it "shows new messages on the Chat tile until the chat is opened" do
    partnership = offer.accept_proposal!(by: poster)
    offer.mark_read_by!(poster)
    offer.post_message(partner, "Ready when you are")
    sign_in(poster)

    visit partner_path(partnership)

    expect(page).to have_content(/1\s+new message\b/)
    expect(page).to have_content("Sam: Ready when you are")

    click_link "Open chat"
    click_link "Overview"

    expect(page).to have_content("You're all caught up")
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
      expect(page).not_to have_button("Edit")

      click_link "Open chat"

      expect(page).to have_content("You ended this partnership.")
      expect(page).not_to have_field("Write a message")
    end

    it "reports from the Chat page" do
      visit chat_partner_path(Partnership.last)

      click_button "Report"
      fill_in "What happened?", with: "Rude"
      click_button "Send report"

      expect(page).to have_content("Thanks for telling us.")
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
      expect(page).not_to have_button("End partnership")
      expect(Partnership.last.end_reason).to eq("Different goals")
    end

    it "keeps the chat box in view on a phone without scrolling" do
      visit chat_partner_path(Partnership.last)
      page.driver.resize(390, 800)
      sleep 0.2

      bottom = page.evaluate_script("document.querySelector('textarea[aria-label=\"Write a message\"]').getBoundingClientRect().bottom")

      expect(bottom).to be <= 800
      expect(page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")).to be <= 0
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

  describe "resources" do
    let!(:partnership) { offer.accept_proposal!(by: poster) }

    it "can be added from the overview, shared with the partner and removed" do
      sign_in(poster)
      visit partner_path(partnership)

      expect(page).to have_content("No links yet")
      click_link "Open resources"

      expect(page).to have_content("Nothing shared yet")
      fill_in "Link", with: "https://www.exercism.org/tracks/python"
      fill_in "Note (optional)", with: "Do two exercises a week"
      click_button "Add link"

      expect(page).to have_link("exercism.org", href: "https://www.exercism.org/tracks/python")
      expect(page).to have_content("Do two exercises a week")
      expect(page).to have_content("Added by you")
      expect(page).to have_field("Link", with: "")

      click_link "Overview"

      expect(page).to have_content(/1\s+link\b/)
      expect(page).to have_content("Latest: exercism.org")

      sign_in(partner)
      visit partner_resources_path(partnership)

      expect(page).to have_content("Added by Maya")
      click_button "Remove exercism.org"

      expect(page).to have_content("Nothing shared yet")
      expect(page).not_to have_link("exercism.org")
    end

    it "fits a phone, with the form above the list" do
      partnership.shared_links.create!(added_by: partner, url: "https://github.com/sam/a-really-long-repository-name-that-goes-on/blob/main/README.md")
      sign_in(poster)
      page.driver.resize(390, 800)
      visit partner_resources_path(partnership)

      expect(page).to have_link("github.com")
      form_bottom = page.evaluate_script("document.querySelector('form').getBoundingClientRect().bottom")
      list_top = page.evaluate_script("document.querySelector('a[href^=\"https://github.com\"]').closest('li').getBoundingClientRect().top")
      expect(list_top).to be > form_bottom
      expect(page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")).to be <= 0
    end

    it "stays readable but can't be changed once the partnership ends" do
      partnership.shared_links.create!(added_by: partner, url: "https://github.com/sam")
      partnership.end!(by: partner)
      sign_in(poster)
      visit partner_resources_path(partnership)

      expect(page).to have_link("github.com")
      expect(page).not_to have_button("Add link")
      expect(page).not_to have_button("Remove github.com")
    end
  end
end
