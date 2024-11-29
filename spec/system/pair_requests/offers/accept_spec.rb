RSpec.describe "accept pair request offer", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  let(:pair_request) { create(:pair_request, user: current_user) }
  let!(:offer) { create(:offer, pair_request:) }

  it "informs user that offer is accepted" do
    visit users_pair_requests_path

    click_link "See applications"
    click_button "Accept"

    expect(page).to have_content("You just scheduled yourself a new pairing session. Happy pairin!")
  end
end
