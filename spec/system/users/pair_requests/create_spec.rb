RSpec.describe "users pair requests", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  it "creates pair request for current user" do
    visit new_users_pair_request_path

    fill_in "Subject", with: "AAA"
    fill_in "Description", with: "BBB"
    fill_in "Duration", with: 45
    pick_future_period!

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
        expect(page).to have_content("must be greater than 0")
      end
    end
  end

  context "when mode is immediate" do
    it "creates a pair request with a single period starting now, ignoring any scheduled periods" do
      visit new_users_pair_request_path

      fill_in "Subject", with: "AAA"
      fill_in "Description", with: "BBB"
      fill_in "Duration", with: 45
      pick_future_period!

      click_button "Immediate"
      fill_in "Goal", with: "Pair on a tricky bug"
      select_option! "Wait time", "30 minutes"
      select_option! "Platform", "Zoom"

      click_button "Create Pair request"

      expect(page).to have_content("AAA")

      pair_request = current_user.pair_requests.find_by!(subject: "AAA")

      expect(pair_request.mode).to eq("immediate")
      expect(pair_request.periods.count).to eq(1)
      expect(pair_request.periods.first.start_at).to be_within(5.seconds).of(Time.current)
    end
  end
end
