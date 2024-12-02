RSpec.describe "search pair requests", type: :system, js: true do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "search by all params" do
    let(:searched_pair_request) { create(:pair_request, subject: "Test", user: user, duration: 45) }
    let(:user) { create(:user, language: "EN", level: "novice") }

    before do
      travel_to("2024-11-11T00:00") do
        tag = create(:tag, name: "Ruby")
        create(:tagging, taggable: searched_pair_request, tag: tag)
        create(:period, periodable: searched_pair_request, start_at: "2024-11-11T12:00")
      end
    end

    it "displays pair requests tagged by searched tag" do
      visit pair_requests_path

      find(:element, "data-testid": "search-btn").click
      fill_in "q_tags_name_eq", with: "Ruby"
      fill_in "q_duration_eq", with: 45
      find("#q_user_level_eq").click
      find("li[data-value='novice']").click
      find("#q_user_language_eq").click
      find("li[data-value='EN']").click
      page.execute_script("document.querySelector('#q_periods_start_at_gteq')._flatpickr.setDate(new Date('2024-11-11T11:59'))")
      page.execute_script("document.querySelector('#q_periods_end_at_lteq')._flatpickr.setDate(new Date('2024-11-11T12:46'))")

      click_button "Go"

      expect(page).to have_content("Test")
    end
  end
end
