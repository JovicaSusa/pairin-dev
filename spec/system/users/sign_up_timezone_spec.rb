RSpec.describe "signing up records the browser's timezone", type: :system do
  it "stores the timezone the browser reports" do
    visit new_user_registration_path
    page.driver.browser.page.command("Emulation.setTimezoneOverride", timezoneId: "Asia/Tokyo")
    visit new_user_registration_path

    fill_in "user_email", with: "tokyo@example.com"
    fill_in "user_password", with: "secret-password-123"
    fill_in "user_password_confirmation", with: "secret-password-123"
    click_button "Sign up"

    expect(page).to have_no_button("Sign up")
    expect(User.find_by(email: "tokyo@example.com").timezone).to eq("Asia/Tokyo")
  end
end
