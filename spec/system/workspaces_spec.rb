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

    it "can be confirmed by the partner, shows as next, and cancelled by either" do
      create(:session, partnership:, proposed_by: poster, start_at: Time.utc(2030, 3, 4, 17, 30), end_at: Time.utc(2030, 3, 4, 18, 30))
      sign_in(partner)
      visit partner_sessions_path(partnership)

      expect(page).to have_content("Maya proposed this")
      click_button "Confirm"

      expect(page).to have_content("Maya proposed it, you confirmed")
      expect(page).not_to have_button("Confirm")

      click_link "Overview"
      expect(page).to have_content("Mon 4 Mar · 12:30–13:30")
      expect(page).to have_content(/1\s+confirmed ahead/)

      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).to have_content("You proposed it, Sam confirmed")
      click_button "Cancel session"
      expect(page).to have_content("Cancel this session? We'll tell Sam.")
      click_button "Yes, cancel it"

      expect(page).to have_content("You cancelled")
      expect(page).not_to have_button("Cancel session")
    end

    it "can be declined by the partner or withdrawn by the proposer" do
      create(:session, partnership:, proposed_by: poster, start_at: Time.utc(2030, 3, 4, 17, 30), end_at: Time.utc(2030, 3, 4, 18, 30))
      create(:session, partnership:, proposed_by: poster, start_at: Time.utc(2030, 3, 5, 17, 30), end_at: Time.utc(2030, 3, 5, 18, 30))
      sign_in(partner)
      visit partner_sessions_path(partnership)

      within(find("li", text: "Mon 4 Mar")) { click_button "Decline" }
      expect(page).to have_content("You declined")

      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).to have_content("Sam declined")
      within(find("li", text: "Tue 5 Mar")) { click_button "Withdraw" }
      expect(page).to have_content("You withdrew this")
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

    it "suggests times you're both usually free, and warns about one outside the partner's hours" do
      (1..7).each do |day|
        create(:availability_window, user: poster, weekday: day, start_minute: 10 * 60, end_minute: 12 * 60)
        create(:availability_window, user: partner, weekday: day, start_minute: 4 * 60, end_minute: 6 * 60)
      end
      first = SessionTimes.new(Partnership.find(partnership.id), viewer: poster.reload).suggestions(60).first.in_time_zone("Europe/Berlin")
      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).to have_content("You're both usually free")
      expect(page).to have_css("button[aria-pressed]", count: 6)

      set_time_field("session_time", "03:00")
      expect(page).to have_content("Outside Sam's usual hours. You can still propose it.")

      find("button[aria-pressed]", match: :first).click
      expect(page).to have_field("Date", with: first.to_date.iso8601)
      expect(page).to have_field("session_time", with: first.strftime("%H:%M"))
      expect(page).to have_css("button[aria-pressed='true']", count: 1)
      expect(page).not_to have_content("Outside Sam's usual hours")

      click_button "Propose session"
      expect(page).to have_content("Waiting for Sam to answer")
      expect(partnership.sessions.sole.start_at).to eq(first)
    end

    it "keeps the page up when the date or time is cleared mid-edit" do
      (1..7).each { |day| create(:availability_window, user: partner, weekday: day, start_minute: 4 * 60, end_minute: 6 * 60) }
      sign_in(poster)
      visit partner_sessions_path(partnership)

      set_time_field("session_time", "03:00")
      expect(page).to have_content("Outside Sam's usual hours")
      set_time_field("session_time", "")
      expect(page).to have_button("Propose session")
      expect(page).not_to have_content("Outside Sam's usual hours")

      set_time_field("session_time", "03:00")
      set_time_field("session_date", "")
      expect(page).to have_button("Propose session")
    end

    it "says when there are no hours to go on" do
      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).to have_content("Sam hasn't added their usual hours yet.")
      expect(page).to have_link("Add your hours", href: availability_path)
      expect(page).not_to have_content("You're both usually free")
    end

    it "lists each partner's hours when they don't overlap" do
      create(:availability_window, user: poster, weekday: 1, start_minute: 8 * 60, end_minute: 9 * 60)
      create(:availability_window, user: partner, weekday: 3, start_minute: 12 * 60, end_minute: 13 * 60)
      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).to have_content("No shared hours in the next week that fit 1 hour.")
      expect(page).to have_content(/Sam is usually free \(your time\): Wed \d+ \w+ 1[78]:00–1[89]:00/)
      expect(page).to have_content(/You're usually free: Mon \d+ \w+ 08:00–09:00/)
    end

    it "adds a confirmed session to Google, Outlook or another calendar from one menu" do
      confirmed = create(:session, partnership:, proposed_by: poster, start_at: Time.utc(2030, 3, 4, 17, 30), end_at: Time.utc(2030, 3, 4, 18, 30))
      confirmed.confirm!(by: partner)
      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).not_to have_link("Google Calendar")
      click_button "Add to calendar"

      expect(page).to have_link("Google Calendar", href: /\Ahttps:\/\/calendar\.google\.com\/calendar\/render\?action=TEMPLATE/)
      expect(page).to have_link("Outlook", href: /\Ahttps:\/\/outlook\.live\.com\/calendar\/0\/deeplink\/compose\?path=/)
      expect(page).to have_link("Apple / other (.ics)", href: calendar_partner_session_path(partnership, confirmed))
    end

    it "offers 15 minutes as the shortest length" do
      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).to have_select("Length", with_options: ["15 min", "30 min"])
      fill_in "Date", with: Date.new(2030, 3, 4)
      set_time_field("session_time", "18:30")
      select "15 min", from: "Length"
      click_button "Propose session"

      expect(page).to have_content("Mon 4 Mar · 18:30–18:45")
    end

    it "has a Join call button on a confirmed session, which stands out from 10 minutes before" do
      later = create(:session, partnership:, proposed_by: poster, start_at: 2.days.from_now.change(min: 0), call_link: "https://meet.google.com/later")
      later.confirm!(by: partner)
      soon = create(:session, partnership:, proposed_by: poster, start_at: 5.minutes.from_now, call_link: "https://meet.google.com/soon")
      soon.confirm!(by: partner)
      create(:session, partnership:, proposed_by: poster, start_at: 3.days.from_now.change(min: 0), call_link: "https://meet.google.com/waiting")
      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).to have_link("Join call", href: "https://meet.google.com/soon", class: "join-call-now")
      expect(page).to have_link("Join call", href: "https://meet.google.com/later")
      expect(page).not_to have_css("a.join-call-now[href='https://meet.google.com/later']")
      expect(page).to have_link("meet.google.com/waiting", href: "https://meet.google.com/waiting")
      expect(page).not_to have_link("Join call", href: "https://meet.google.com/waiting")
      expect(page).not_to have_link("meet.google.com/soon")
    end

    it "keeps Join call on a session that has started but not ended" do
      ongoing = create(:session, partnership:, proposed_by: poster, start_at: 1.day.from_now.change(min: 0), call_link: "https://meet.google.com/now")
      ongoing.confirm!(by: partner)
      ongoing.update_columns(start_at: 5.minutes.ago, end_at: 55.minutes.from_now)
      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).to have_link("Join call", href: "https://meet.google.com/now", class: "join-call-now")
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

    it "stays readable, cancelled, and takes no proposals once the partnership ends" do
      create(:session, partnership:, proposed_by: partner)
      partnership.end!(by: partner)
      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(page).to have_content("Cancelled when the partnership ended")
      expect(page).not_to have_button("Propose session")
      expect(page).not_to have_button("Confirm")

      visit partner_path(partnership)
      expect(page).not_to have_link("Propose a session")
    end

    it "shows whether past sessions took place, and asks without sign-in" do
      took_place = create(:session, partnership:, proposed_by: poster, status: "confirmed", start_at: 3.days.from_now.change(min: 0))
      took_place.update_columns(start_at: Time.utc(2026, 3, 2, 17, 30), end_at: Time.utc(2026, 3, 2, 18, 30))
      no_show = create(:session, partnership:, proposed_by: poster, status: "confirmed", start_at: 4.days.from_now.change(min: 0))
      no_show.update_columns(start_at: Time.utc(2026, 3, 3, 17, 30), end_at: Time.utc(2026, 3, 3, 18, 30))
      waiting = create(:session, partnership:, proposed_by: poster, status: "confirmed", start_at: 5.days.from_now.change(min: 0))
      waiting.update_columns(start_at: 2.hours.ago, end_at: 1.hour.ago)
      took_place.answers.create!(user: poster).answer!(true)
      took_place.answers.create!(user: partner).answer!(false)
      no_show.answers.create!(user: partner).answer!(false)
      answer = waiting.answers.create!(user: partner)

      visit session_answer_path(token: answer.generate_token_for(:answer), answer: "yes")
      expect(page).to have_content("Did your session with Maya happen?")
      click_button "Confirm: Yes"
      expect(page).to have_content("Thanks, got it")
      click_button "Change to No"
      expect(page).to have_content("You said no")

      sign_in(poster)
      visit partner_sessions_path(partnership)

      expect(find("li", text: "Mon 2 Mar")).to have_content("Took place")
      expect(find("li", text: "Tue 3 Mar")).to have_content("Didn't happen")
      expect(find("li", text: "Tue 3 Mar")[:class]).to include("opacity-70")
      expect(page).to have_content("Didn't happen", count: 2)
    end

    it "says the partners have been asked while nobody has answered yet" do
      unanswered = create(:session, partnership:, proposed_by: poster, status: "confirmed", start_at: 3.days.from_now.change(min: 0))
      unanswered.update_columns(start_at: Time.utc(2026, 3, 2, 17, 30), end_at: Time.utc(2026, 3, 2, 18, 30))
      sign_in(partner)
      visit partner_sessions_path(partnership)

      within(find("li", text: "Mon 2 Mar")) do
        expect(page).to have_content("Done")
        expect(page).to have_content("Did it happen? We've emailed you both to ask")
      end
    end

    it "offers Add to calendar on a confirmed upcoming session only" do
      confirmed = create(:session, partnership:, proposed_by: poster, status: "confirmed", start_at: 3.days.from_now.change(min: 0))
      create(:session, partnership:, proposed_by: poster, start_at: 4.days.from_now.change(min: 0))
      sign_in(partner)
      visit partner_sessions_path(partnership)

      expect(page).to have_button("Add to calendar", count: 1)
      click_button "Add to calendar"
      link = find_link("Apple / other (.ics)")
      expect(link[:href]).to end_with(calendar_partner_session_path(partnership, confirmed))
      expect(link[:download]).not_to be_nil
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
