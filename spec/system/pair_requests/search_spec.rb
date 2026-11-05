RSpec.describe "search pair requests", type: :system, js: true do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "search by all params" do
    let(:searched_pair_request) { create(:pair_request, subject: "Test", user: user, commitment: "open_ended") }
    let(:user) { create(:user, language: "EN", level: "novice") }

    before do
      tag = create(:tag, name: "Ruby")
      create(:tagging, taggable: searched_pair_request, tag: tag)
    end

    it "displays pair requests tagged by searched tag" do
      visit pair_requests_path

      select_option!("Select tag", "Ruby")
      select_option!("Select commitment", "Open-ended")
      select_option!("Select level", "Novice")
      select_option!("Select language", "English")

      click_button "Show results"

      expect(page).to have_content("Test")
    end
  end
end
