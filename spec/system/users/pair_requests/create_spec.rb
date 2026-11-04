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
    click_button "Post partner search"

    expect(page).to have_content("AAA")
    expect(page).to have_content("BBB")
    expect(page).to have_content("Partner · 1–3 months")
  end

  it "saves the chosen commitment" do
    visit new_users_pair_request_path

    fill_in "Subject", with: "AAA"
    fill_in "Description", with: "BBB"
    select_option!("Commitment", "Open-ended")
    click_button "Post partner search"

    expect(page).to have_content("Partner · Open-ended")
    expect(PairRequest.find_by!(subject: "AAA")).to be_open_ended
  end

  context "when details not provided" do
    it "displays errors" do
      visit new_users_pair_request_path

      fill_in "Subject", with: ""
      fill_in "Description", with: ""
      click_button "Post partner search"

      within(".pair_request_subject") do
        expect(page).to have_content("can't be blank")
      end
      within(".pair_request_description") do
        expect(page).to have_content("can't be blank")
      end
    end
  end
end
