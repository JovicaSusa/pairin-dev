RSpec.describe "search pair requests", type: :system, js: true do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "search by all params" do
    let(:searched_pair_request) { create(:pair_request, subject: "Test", user: user, duration: 45) }
    let(:user) { create(:user, language: "EN", level: "novice") }
    let(:search_date) { 3.days.from_now.to_date }

    before do
      tag = create(:tag, name: "Ruby")
      create(:tagging, taggable: searched_pair_request, tag: tag)
    end

    it "displays pair requests tagged by searched tag" do
      visit pair_requests_path

      click_button "Filter"
      select_option!("Select tag", "Ruby")
      fill_in "Duration", with: 45
      select_option!("Select level", "Novice")
      select_option!("Select language", "English")
      select_calendar_date!("Pick a start date", search_date)
      select_calendar_date!("Pick an end date", search_date)

      click_button "Search"

      expect(page).to have_content("Test")
    end
  end
end
