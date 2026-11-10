RSpec.describe "onboarding", type: :system do
  let(:user) { create(:user, name: nil, level: nil) }

  before do
    create(:tag, name: "python")
    create(:tag, name: "pascal")
    sign_in(user)
  end

  def answer_about_you(name: "Maya")
    expect(page).to have_content("What should partners call you?")
    expect(page).not_to have_button("Skip setup")
    expect(page).to have_button("Next", disabled: true)
    fill_in "Your name", with: name
    click_button "Next"
    click_button "Skip this"
    click_button "Skip this"
  end

  it "goes one question at a time, with the tag search, to a live search and matches" do
    match = create(:pair_request, subject: "Python buddy wanted")
    create(:tagging, taggable: match, tag: Tag.find_by!(name: "python"))

    visit onboarding_path

    expect(page).to have_content("What should partners call you?")
    expect(page).to have_button("Back", disabled: true)
    expect(page).not_to have_button("Skip setup")
    fill_in "Your name", with: "Maya"
    click_button "Next"

    expect(page).to have_content("Where are you at?")
    click_button "Just starting"
    click_button "Next"

    expect(page).to have_content("Anything partners should know about you?")
    fill_in "About you", with: "Learning Python after work"
    click_button "Next"

    expect(page).to have_content("What do you want to learn or practise?")
    expect(page).to have_button("Next", disabled: true)
    expect(page).to have_button("Skip setup")

    field = find('[role="combobox"]')
    field.send_keys("pyth")
    expect(page).to have_css('[role="option"]', text: "python")
    expect(page).not_to have_css('[role="option"]', text: "pascal")
    field.send_keys(:enter)
    expect(page).to have_button("Remove python")

    field.send_keys("web scraping")
    expect(page).to have_css('[role="option"]', text: 'Add "web scraping"')
    field.send_keys(:enter)
    expect(page).to have_button("Remove web scraping")

    click_button "Remove web scraping"
    expect(page).not_to have_button("Remove web scraping")

    click_button "Next"
    expect(page).to have_content("What's your goal, in a line?")
    fill_in "Your goal", with: "Finish a course"

    click_button "Next"
    expect(page).to have_content("How long would you like to commit?")
    click_button "Open-ended"

    click_button "Back"
    expect(page).to have_field("Your goal", with: "Finish a course")
    click_button "Next"

    click_button "Next"
    expect(page).to have_content("When are you usually free?")
    click_button "Add"
    expect(page).to have_content("Tuesday 18:00–20:00")

    click_button "Find me a partner"

    expect(page).to have_content("Your partner search is live!")
    expect(page).to have_content("Partner · Open-ended")
    expect(page).to have_content("People looking for the same thing")
    expect(page).to have_content("Python buddy wanted")
    expect(user.reload.pair_requests.sole).to have_attributes(description: "Finish a course", commitment: "open_ended")
    expect(user).to have_attributes(name: "Maya", level: "novice", about: "Learning Python after work")
  end

  it "skips the optional steps" do
    visit onboarding_path
    answer_about_you

    find('[role="combobox"]').send_keys("python", :enter)
    click_button "Next"
    click_button "Skip this"
    click_button "Skip this"
    click_button "Find me a partner"

    expect(page).to have_content("Your partner search is live!")
    expect(user.reload.pair_requests.sole.commitment).to eq("one_to_three_months")
  end

  it "skips everything, then reopens from the banner" do
    visit onboarding_path
    answer_about_you(name: "Sam")

    click_button "Skip setup"

    expect(page).to have_content("Finish setting up to get matched.")
    expect(user.reload.name).to eq("Sam")
    click_link "Finish setting up"

    expect(page).to have_content("What should partners call you?")
    expect(page).to have_field("Your name", with: "Sam")
  end

  it "asks an existing account without a name once, then carries on" do
    create(:pair_request, user:)

    visit partners_path

    expect(page).to have_content("What should partners call you?")
    fill_in "Your name", with: "Maya"
    click_button "Continue"

    expect(page).to have_current_path(partners_path)
    expect(user.reload.name).to eq("Maya")
  end
end
