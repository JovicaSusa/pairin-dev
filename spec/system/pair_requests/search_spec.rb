RSpec.describe "search pair requests", type: :system, js: true do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "search by tag name" do
    let!(:pair_request_with_searched_tag) { create(:pair_request, subject: "AAA") }
    let!(:tagging) { create(:tagging, taggable: pair_request_with_searched_tag, tag: tag) }
    let!(:tag) { create(:tag, name: "Ruby") }
    let!(:not_searched_pair_request) { create(:pair_request, subject: "BBB") }

    it "displays pair requests tagged by searched tag" do
      visit pair_requests_path

      find(".ss-values").click
      find(".ss-option", text: "Ruby").click
      click_button "Go"

      expect(page).to have_content("AAA")
      expect(page).not_to have_content("BBB")
    end
  end
end
