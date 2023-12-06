RSpec.describe "view pair request offers", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  let(:pair_request) { create(:pair_request, user: current_user) }
  let!(:offer_for_pair_request) { create(:offer, pair_request:, message: "Hey!") }
  let!(:other_offer) { create(:offer, message: "Ho!") }

  it "displays offers for given pair request" do
    visit pair_request_offers_path(pair_request)

    expect(page).to have_content("Hey")
    expect(page).not_to have_content("Ho")
  end
end
