RSpec.describe "users pair requests", type: :system do
  let(:current_user) { create(:user) }

  before do
    create(:availability_window, user: current_user)
    sign_in(current_user)
  end

  it "creates pair request for current user" do
    visit new_users_pair_request_path

    fill_in "Subject", with: "AAA"
    fill_in "Description", with: "BBB"
    fill_in "Duration", with: 45

    click_button "Create Pair request"

    expect(page).to have_content("AAA")
    expect(page).to have_content("BBB")
  end

  context "when details not provided" do
    it "displays errors" do
      visit new_users_pair_request_path

      fill_in "Subject", with: ""
      fill_in "Description", with: ""
      fill_in "Duration", with: 0

      click_button "Create Pair request"

      within(".pair_request_subject") do
        expect(page).to have_content("can't be blank")
      end
      within(".pair_request_description") do
        expect(page).to have_content("can't be blank")
      end
      within(".pair_request_duration") do
        expect(page).to have_content("must be between 1 and 180 minutes")
      end
    end
  end
end
