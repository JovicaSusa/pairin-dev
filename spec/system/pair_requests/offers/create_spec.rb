RSpec.describe "create pair request offer", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  let!(:period) { create(:period, periodable: pair_request) }
  let(:pair_request) { create(:pair_request, with_periods: false) }

  it "creates offer for pair request" do
    visit pair_requests_path

    click_link "Apply"
    fill_in "Message", with: "Let's hack!"
    find_field("offer_period_id").click
    find_field("#{period.start_at.to_fs(:short)} : #{period.end_at.to_fs(:short)}").click

    click_button "Apply"

    expect(page).to have_content("We have sent your offer, good luck!")
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
