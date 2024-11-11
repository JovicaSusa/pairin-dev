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

      fill_in "q_tags_name_eq", with: "Ruby"
      click_button "Go"

      expect(page).to have_content("AAA")
      expect(page).not_to have_content("BBB")
    end
  end

  context "pagination" do
    let!(:pair_request_one) { create(:pair_request, subject: "AAA", duration: 45) }
    let!(:pair_request_two) { create(:pair_request, subject: "BBB", duration: 45) }
    let!(:pair_request_three) { create(:pair_request, subject: "CCC", duration: 60) }

    before do
      Pagy::DEFAULT[:limit] = 1
    end

    it "properly paginates result" do
      visit pair_requests_path

      fill_in "q_duration_eq", with: 45
      click_button "Go"

      expect(page).to have_content("AAA")
      expect(page).not_to have_content("BBB")

      scroll_to("#pair-requests-page-2")

      expect(page).to have_content("BBB")
    end
  end
end
