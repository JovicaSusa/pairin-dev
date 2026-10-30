RSpec.describe "switching a pair request on and off", type: :system do
  let(:current_user) { create(:user) }
  let!(:pair_request) { create(:pair_request, user: current_user, subject: "Learn Rust together") }

  before { sign_in(current_user) }

  it "lets the poster switch a request off and back on from My requests" do
    visit users_pair_requests_path

    click_button "Switch off"

    expect(page).to have_content("Off: hidden from others")
    expect(page).to have_button("Switch on")
    expect(pair_request.reload).to be_paused

    click_button "Switch on"

    expect(page).not_to have_content("Off: hidden from others")
    expect(page).to have_button("Switch off")
    expect(pair_request.reload).not_to be_paused
  end
end
