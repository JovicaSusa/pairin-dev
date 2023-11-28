RSpec.describe "create pair request offer", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  let!(:pair_request) { create(:pair_request) }

  it "creates offer for pair request" do
    visit pair_requests_path

    click_link "Make an offer"
    fill_in "Message", with: "Let's hack!"

    click_button "Send offer"

    expect(page).to have_content("We have sent your offer, good luck!")
  end

  context "when details not provided" do
    it "displays errors" do
      visit pair_requests_path

      click_link "Make an offer"
      fill_in "Message", with: ""

      click_button "Send offer"

      expect(page).to have_content("can't be blank")
    end
  end

  context "when user already offered" do
    before { create(:offer, pair_request:, offerer: current_user) }

    it "displays errors" do
      visit pair_requests_path

      click_link "Make an offer"
      fill_in "Message", with: "Hey!"

      click_button "Send offer"

      expect(page).to have_content("has already been taken")
    end
  end
end
