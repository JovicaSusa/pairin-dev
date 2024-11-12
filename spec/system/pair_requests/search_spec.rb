RSpec.describe "search pair requests", type: :system, js: true do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "search by all params" do
    let(:searched_pair_request) { create(:pair_request, subject: "Test", user: user, duration: 45) }
    let(:user) { create(:user, language: "EN", level: "novice") }

    before do
      tag = create(:tag, name: "Ruby")
      create(:tagging, taggable: searched_pair_request, tag: tag)
      create(:period, periodable: searched_pair_request, start_at: 2.minutes.from_now)
    end

    it "displays pair requests tagged by searched tag" do
      visit pair_requests_path

      fill_in "q_tags_name_eq", with: "Ruby"
      fill_in "q_duration_eq", with: 45
      find("#q_user_level_eq").click
      find("li[data-value='novice']").click
      find("#q_user_language_eq").click
      find("li[data-value='EN']").click
      # fill_in "q_user_language_eq", with: "EN"
      fill_in "q_periods_start_at_gteq", with: 1.minute.from_now.to_s
      fill_in "q_periods_end_at_lteq", with: 3.minutes.from_now.to_s
      click_button "Go"

      expect(page).to have_content("Test")
    end
  end
end
