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

  describe "sessions" do
    let!(:partnership) { offer.accept_proposal!(by: poster) }

    # Cuprite can't type into a native time field, so set it the way React
    # sees a change.
    def set_time_field(id, value)
      page.execute_script(<<~JS, id, value)
        const [id, value] = arguments;
        const input = document.getElementById(id);
        Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set.call(input, value);
        input.dispatchEvent(new Event("input", { bubbles: true }));
      JS
    end

    before do
      poster.update!(timezone: "Europe/Berlin")
      partner.update!(timezone: "America/New_York")
    end

    it "can be proposed from the overview, and the partner sees it waiting for them" do
      sign_in(poster)
      visit partner_path(partnership)

      expect(page).to have_content("Nothing planned yet")
      click_link "Propose a session"

      expect(page).to have_content("No sessions yet")
      expect(page).to have_content("Times are in your timezone, Europe/Berlin.")
      fill_in "Date", with: Date.new(2030, 3, 4)
      set_time_field("session_time", "18:30")
      select "1.5 hours", from: "Length"
      fill_in "Call link (optional)", with: "https://meet.google.com/abc-defg-hij"
      click_button "Propose session"

      expect(page).to have_content("Mon 4 Mar · 18:30–20:00")
      expect(page).to have_content("12:30–14:00 GMT-5 for Sam")
      expect(page).to have_content("Waiting for Sam to answer")
      expect(page).to have_link("meet.google.com/abc-defg-hij", href: "https://meet.google.com/abc-defg-hij")

      sign_in(partner)
      visit partner_path(partnership)

      expect(page).to have_content("1 waiting for your answer")
      click_link "Open sessions"

      expect(page).to have_content("Mon 4 Mar · 12:30–14:00 GMT-5")
      expect(page).to have_content("Maya proposed this")
    end

    it "says what's wrong with a time in the past" do
      sign_in(poster)
      visit partner_sessions_path(partnership)

      fill_in "Date", with: Date.yesterday
      page.execute_script("document.getElementById('session_date').removeAttribute('min')")
      click_button "Propose session"

      expect(page).to have_content("Start must be in the future")
      expect(partnership.sessions).to be_empty
    end

    it "shows the next confirmed session on the overview" do
      create(:session, partnership:, proposed_by: partner, status: "confirmed", start_at: Time.utc(2030, 3, 4, 17, 30), end_at: Time.utc(2030, 3, 4, 18, 30), call_link: "https://zoom.us/j/1")
      sign_in(poster)
      visit partner_path(partnership)

      expect(page).to have_content("Mon 4 Mar · 18:30–19:30")
      expect(page).to have_link("Join call", href: "https://zoom.us/j/1")
      expect(page).to have_content(/1\s+confirmed ahead/)
    end

    it "fits a phone, with the form above the list" do
      create(:session, partnership:, proposed_by: partner, call_link: "https://meet.google.com/a-really-long-meeting-code-that-keeps-going-and-going")
      sign_in(poster)
      page.driver.resize(390, 800)
      visit partner_sessions_path(partnership)

      expect(page).to have_content("Sam proposed this")
      form_bottom = page.evaluate_script("document.querySelector('form').getBoundingClientRect().bottom")
      list_top = page.evaluate_script("[...document.querySelectorAll('h2')].find((h) => h.textContent === 'Upcoming').getBoundingClientRect().top")
      expect(list_top).to be > form_bottom
      expect(page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")).to be <= 0
    end

    it "stays readable but takes no proposals once the partnership ends" do
      create(:session, partnership:, proposed_by: partner)
      partnership.end!(by: partner)
      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).to have_content("Sam proposed this")
      expect(page).not_to have_button("Propose session")

      visit partner_path(partnership)
      expect(page).not_to have_link("Propose a session")
    end
  end
end
