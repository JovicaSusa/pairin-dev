RSpec.describe "generates expected activites", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "when pair request created" do
    it "displays expected activity" do
      visit activities_path
      visit users_pair_requests_path

      click_link "New Request"
      fill_in "Subject", with: "AAA"
      fill_in "Description", with: "BBB"
      fill_in "Duration", with: 45
      fill_in "Start at", with: "2024-11-14 12:00"

      click_button "Create Pair request"

      visit activities_path

      expect(page).to have_one_of_the_texts(I18n.t("activities.pair_request_created.titles"))
      expect(page).to have_one_of_the_texts(I18n.t("activities.pair_request_created.content"))
    end
  end

  context "when pair request offer accepted" do
    let(:pair_request) { create(:pair_request, user: current_user) }
    let!(:offer) { create(:offer, pair_request:) }

    it "displays expected activity" do
      visit users_pair_requests_path

      click_link "Offers"
      click_button "Accept"

      visit activities_path

      expect(page).to have_one_of_the_texts(I18n.t("activities.session_scheduled.titles"))
      expect(page).to have_one_of_the_texts(I18n.t("activities.session_scheduled.content"))
    end
  end

  context "when offer sent" do
    let!(:pair_request) { create(:pair_request) }

    it "creates expected activity" do
      visit pair_requests_path

      click_link "Make an offer"
      fill_in "Message", with: "Let's hack!"

      click_button "Send offer"

      visit activities_path
    end
  end
end
