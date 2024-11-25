RSpec.describe "update pair request call link", type: :system do
  let(:current_user) { create(:user) }
  let!(:pair_request) { create(:pair_request, user: current_user) }

  before do
    create(:offer, :accepted, pair_request:)
    create(:session, sessionable: pair_request)
    sign_in(current_user)
  end

  it "updates pair request sesssion call link" do
    visit users_pair_requests_path

    fill_in :pair_request_sessions_attributes_0_call_link, with: "www.something.com"
    click_button "Add"

    expect(page).to have_content("Successfuly added!")
  end
end
