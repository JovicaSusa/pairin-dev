RSpec.describe "weekly hours and timezone", type: :system do
  let(:user) { create(:user, timezone: "UTC") }

  before { sign_in(user) }

  it "suggests the browser's timezone and manages weekly windows" do
    visit availability_path
    page.driver.browser.page.command("Emulation.setTimezoneOverride", timezoneId: "Asia/Tokyo")
    visit availability_path

    expect(page).to have_select("Timezone", selected: "Asia/Tokyo")
    expect(page).to have_content("Detected from your browser")
    click_button "Save timezone"
    expect(page).to have_content("Timezone saved.")
    expect(user.reload.timezone).to eq("Asia/Tokyo")

    select "Tuesday", from: "Day"
    select "18:00", from: "From"
    select "20:00", from: "To"
    click_button "Add hours"

    expect(page).to have_content("Tuesday 18:00–20:00")

    click_button "Remove Tuesday 18:00–20:00"

    expect(page).to have_content("Removed.")
    expect(page).not_to have_content("Tuesday 18:00–20:00")
    expect(user.availability_windows).to be_empty
  end
end
