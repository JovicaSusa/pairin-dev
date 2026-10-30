RSpec.describe "signing up records the browser's timezone", type: :system do
  it "stores the timezone the browser reports" do
    visit new_user_registration_path
    page.driver.browser.page.command("Emulation.setTimezoneOverride", timezoneId: "Asia/Tokyo")
    visit new_user_registration_path

    fill_in "user_email", with: "tokyo@example.com"
    fill_in "user_date_of_birth", with: "2000-01-15"
    fill_in "user_password", with: "secret-password-123"
    fill_in "user_password_confirmation", with: "secret-password-123"
    click_button "Sign up"

    expect(page).to have_no_button("Sign up")
    user = User.find_by(email: "tokyo@example.com")
    expect(user.timezone).to eq("Asia/Tokyo")
    expect(user.date_of_birth).to eq(Date.new(2000, 1, 15))
  end
end
