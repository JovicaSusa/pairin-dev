RSpec.describe "users pair requests", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  it "creates pair request for current user" do
    visit users_pair_requests_path

    click_link "New Request"
    fill_in "Subject", with: "AAA"
    fill_in "Description", with: "BBB"

    click_button "Create Pair request"

    expect(page).to have_content("AAA")
    expect(page).to have_content("BBB")
  end

  context "when details not provided" do
    it "displays errors" do
      visit users_pair_requests_path

      click_link "New Request"
      fill_in "Subject", with: ""
      fill_in "Description", with: ""

      click_button "Create Pair request"

      within(".pair_request_subject") do
        expect(page).to have_content("can't be blank")
      end
      within(".pair_request_description") do
        expect(page).to have_content("can't be blank")
      end
    end
  end
end
