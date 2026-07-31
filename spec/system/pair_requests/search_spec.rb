RSpec.describe "search pair requests", type: :system, js: true do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "search by all params" do
    let(:searched_pair_request) { create(:pair_request, subject: "Test", user: user, duration: 45) }
    let(:user) { create(:user, language: "EN", level: "novice") }
    let(:period_start_at) { 3.days.from_now.change(hour: 12, min: 0) }

    before do
      tag = create(:tag, name: "Ruby")
      create(:tagging, taggable: searched_pair_request, tag: tag)
      create(:period, periodable: searched_pair_request, start_at: period_start_at)
    end

    it "displays pair requests tagged by searched tag" do
      visit pair_requests_path

      click_button "Filter"
      select_option!("Select tag", "Ruby")
      fill_in "Duration", with: 45
      select_option!("Select level", "Novice")
      select_option!("Select language", "English")
      select_calendar_date!("Pick a start date", period_start_at.to_date - 1.day)
      select_calendar_date!("Pick an end date", period_start_at.to_date + 1.day)

      click_button "Search"

      expect(page).to have_content("Test")
    end
  end
end
