RSpec.describe "display pair requests", type: :system do
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

  context "when current user already sent an offer for one of the requests" do
    before do
      create(:offer, offerer: current_user, pair_request: other_user_pair_request)
    end

    it "doesn't display button to make an offer for request with an offer from current user" do
      visit pair_requests_path

      expect(page).to have_content("Apply")
      expect(page).to have_content("You have already sent an offer")
    end
  end

  context "when another user has an immediate pair request live now" do
    let!(:live_pair_request) do
      pair_request = create(:pair_request, :immediate, subject: "GGG", description: "HHH", with_periods: false)
      create(:period, periodable: pair_request, start_at: Time.current)
      pair_request
    end

    it "displays it in the Live now section" do
      visit pair_requests_path

      expect(page).to have_content("Live now")
      expect(page).to have_content("GGG")
    end
  end
end
