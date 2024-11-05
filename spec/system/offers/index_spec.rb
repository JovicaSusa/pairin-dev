RSpec.describe "view sent offers", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  let!(:offer) { create(:offer, offerer: current_user, message: "Hello") }
  let(:users_pair_request) { create(:pair_request, user: current_user) }
  let!(:offer_for_users_pair_request) { create(:offer, pair_request: users_pair_request, message: "Hey!") }

  it "displays current users sent offers" do
    visit users_offers_path

    expect(page).to have_content("Hello")
    expect(page).not_to have_content("Hey")
  end
end
