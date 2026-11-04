RSpec.describe "create pair request offer", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  let!(:pair_request) { create(:pair_request) }

  it "creates offer for pair request" do
    visit pair_requests_path

    click_link "Apply"
    fill_in "Message", with: "Let's hack!"
    click_button "Apply"

    expect(page).to have_content("We've emailed the poster")
    expect(Offer.last.period).to be_nil
  end

  context "when details not provided" do
    it "displays errors" do
      visit pair_requests_path

      click_link "Apply"
      fill_in "Message", with: ""

      click_button "Apply"

      expect(page).to have_content("can't be blank")
    end
  end
end
