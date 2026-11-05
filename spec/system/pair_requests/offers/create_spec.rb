RSpec.describe "apply to a partner search", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  let!(:pair_request) { create(:pair_request, subject: "Python buddy", user: create(:user, name: "Maya")) }

  def fill_in_answers
    fill_in "What do you want to get out of this?", with: "Finish the course"
    select_option!("How often can you pair?", "Twice a week")
    select_option!("How long can you commit?", "A few weeks")
    fill_in "Your message to Maya", with: "Let's hack!"
  end

  it "applies from a drawer over the list" do
    visit pair_requests_path

    click_button "Apply"

    within('[role="dialog"]') do
      expect(page).to have_content("Apply to Maya")
      expect(page).to have_content(pair_request.description)
      expect(page).to have_content("Maya is looking for: 1–3 months")
      expect(page).not_to have_content("Your level")
    end

    # Dropdown options open outside the drawer, so these aren't scoped to it.
    fill_in_answers
    click_button "Send application"

    expect(page).to have_content("We've emailed the poster")
    expect(page).not_to have_css('[role="dialog"]')
    expect(page).to have_content("You've already applied")
    expect(Offer.last).to have_attributes(goal: "Finish the course", how_often: "twice_a_week", how_long: "few_weeks", period: nil)
  end

  it "shows errors in the drawer and keeps what was typed" do
    visit pair_requests_path

    click_button "Apply"

    within('[role="dialog"]') do
      fill_in "What do you want to get out of this?", with: "Finish the course"
      click_button "Send application"

      expect(page).to have_content("can't be blank")
      expect(page).to have_field("What do you want to get out of this?", with: "Finish the course")
    end
  end

  it "asks for a level once when the profile has none" do
    current_user.update!(level: nil)

    visit pair_requests_path

    click_button "Apply"

    fill_in_answers
    select_option!("Your level", "Competent")
    click_button "Send application"

    expect(page).to have_content("We've emailed the poster")
    expect(current_user.reload.level).to eq("competent")
  end

  it "closes only an open dropdown on Escape, keeping what was typed" do
    visit pair_requests_path
    click_button "Apply"
    fill_in "What do you want to get out of this?", with: "Finish the course"

    click_button "How often can you pair?"
    expect(page).to have_css('[role="listbox"]')
    find("body").send_keys(:escape)

    expect(page).not_to have_css('[role="listbox"]')
    expect(page).to have_css('[role="dialog"]')
    expect(page).to have_field("What do you want to get out of this?", with: "Finish the course")

    find("body").send_keys(:escape)
    expect(page).not_to have_css('[role="dialog"]')
  end

  it "keeps keyboard focus inside the drawer, and returns it afterwards" do
    visit pair_requests_path
    apply = find_button("Apply")
    apply.click

    20.times do
      find("body").send_keys(:tab)
      expect(page.evaluate_script("!!document.activeElement.closest('[role=dialog]')")).to be(true)
    end

    click_button "Close"

    expect(page).not_to have_css('[role="dialog"]')
    expect(page.evaluate_script("document.activeElement.textContent")).to eq("Apply")
  end

  it "names the filters for screen readers" do
    visit pair_requests_path

    expect(page).to have_css("label[for='filter_tags']", text: "Tags")
    expect(page).to have_css("button#filter_commitment")
    expect(page.evaluate_script("document.querySelector('#filter_level').labels.length")).to eq(1)
  end

  it "lines the filter panel up with the first card" do
    visit pair_requests_path

    panel = page.evaluate_script("document.querySelector('aside.rounded-2xl').getBoundingClientRect().top")
    card = page.evaluate_script("document.querySelector('h3').closest('.rounded-2xl').getBoundingClientRect().top")

    expect((panel - card).abs).to be <= 1
  end

  it "closes the drawer without applying" do
    visit pair_requests_path

    click_button "Apply"
    click_button "Close"

    expect(page).not_to have_css('[role="dialog"]')
    expect(Offer.count).to eq(0)
  end

  it "also works on the full page that email links open" do
    visit new_pair_request_offer_path(pair_request)

    fill_in_answers
    click_button "Send application"

    expect(page).to have_content("We've emailed the poster")
  end
end
