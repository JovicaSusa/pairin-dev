require "rails_helper"

RSpec.describe "Logging out", type: :system do
  it "loads the home page in full, rather than inside the app" do
    sign_in(create(:user))
    visit pair_requests_path

    click_button "Log out"

    expect(page).to have_link("Sign up")
    expect(page).to have_current_path(root_path)
    expect(page).not_to have_css("iframe")
    expect(page).not_to have_content("Log out")
  end
end
