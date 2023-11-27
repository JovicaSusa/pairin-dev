RSpec.describe "users pair requests", type: :system do
  let(:current_user) { create(:user) }

  let!(:current_user_pair_request_one) do
    create(:pair_request, user: current_user, subject: "AAA", description: "BBB")
  end
  let!(:current_user_pair_request_two) do
    create(:pair_request, user: current_user, subject: "CCC", description: "DDD")
  end
  let!(:other_user_pair_request) do
    create(:pair_request, subject: "EEE", description: "FFF")
  end

  before { sign_in(current_user) }

  it "displays users pair requests" do
    visit users_pair_requests_path

    expect(page).to have_content("AAA")
    expect(page).to have_content("CCC")
    expect(page).not_to have_content("EEE")
  end
end
