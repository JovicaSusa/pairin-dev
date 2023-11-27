RSpec.describe "users pair requests", type: :system do
  let(:current_user) { create(:user) }

  let!(:current_user_pair_request_one) do
    create(:pair_request, user: current_user, subject: "AAA", description: "BBB")
  end
  let!(:other_user_pair_request_two) { create(:pair_request, subject: "CCC", description: "DDD") }
  let!(:other_user_pair_request) { create(:pair_request, subject: "EEE", description: "FFF") }

  before { sign_in(current_user) }

  it "displays non current users pair requests" do
    visit pair_requests_path

    expect(page).not_to have_content("AAA")
    expect(page).to have_content("CCC")
    expect(page).to have_content("EEE")
  end
end
