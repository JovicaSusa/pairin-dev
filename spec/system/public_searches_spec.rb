RSpec.describe "sharing a partner search", type: :system do
  let(:poster) { create(:user, name: "Maya") }
  let!(:search) { create(:pair_request, user: poster, subject: "Python buddy") }

  it "gives the poster a link to copy" do
    sign_in(poster)
    visit users_pair_requests_path

    click_button "Share"

    expect(page).to have_field(with: /#{Regexp.escape("/s/#{search.share_token}")}\z/)
    expect(page).to have_content("Anyone with this link can read this search and apply.")
    click_button "Copy"
  end

  it "takes a non-member from the link to the form, and marks the application" do
    visit public_search_path(token: search.share_token)

    expect(page).to have_content("Python buddy")
    click_link "Apply to Maya"
    expect(page).to have_current_path(new_user_registration_path)

    fill_in "Email", with: "new@example.com"
    fill_in "Password", with: "Password33*", match: :first
    fill_in "Password confirmation", with: "Password33*"
    fill_in "Date of birth", with: Date.new(1990, 6, 15)
    click_button "Sign up"

    user = nil
    Timeout.timeout(5) { sleep 0.1 until (user = User.find_by(email: "new@example.com")) }
    user.confirm

    visit new_user_session_path
    fill_in "Email", with: "new@example.com"
    fill_in "Password", with: "Password33*"
    click_button "Log in"

    # A new account gives a name first, then carries on to the form (#262).
    expect(page).to have_content("What should partners call you?")
    fill_in "Your name", with: "Alex"
    click_button "Continue"

    expect(page).to have_content("What do you want to get out of this?")
    expect(page).to have_content("Your level")

    fill_in "What do you want to get out of this?", with: "Finish the course"
    select_option!("How often can you pair?", "Twice a week")
    select_option!("How long can you commit?", "A few weeks")
    select_option!("Your level", "Competent")
    fill_in "Your message to Maya", with: "A friend sent me this"
    click_button "Send application"

    expect(page).to have_content("Application sent!")
    expect(Offer.last).to have_attributes(offerer: user, pair_request: search, via_share_link: true)
  end
end
