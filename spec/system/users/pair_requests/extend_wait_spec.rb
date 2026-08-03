RSpec.describe "extend wait time on an unmatched immediate pair request", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "when the request is live and hasn't been matched" do
    let!(:pair_request) do
      pr = create(:pair_request, :immediate, user: current_user, wait_minutes: 30, subject: "GGG", with_periods: false)
      create(:period, periodable: pr, start_at: Time.current)
      pr
    end

    it "shows the live badge and lets the requester keep waiting" do
      visit users_pair_requests_path

      expect(page).to have_content("GGG")
      expect(page).to have_content("Live now")

      click_button "Keep waiting"

      expect(page).to have_content("We'll keep waiting a bit longer!")
    end
  end

  context "when the wait window has already elapsed" do
    let!(:pair_request) do
      pr = create(:pair_request, :immediate, user: current_user, wait_minutes: 15, subject: "HHH", with_periods: false)
      period = create(:period, periodable: pr, start_at: Time.current)
      period.update_column(:start_at, 30.minutes.ago)
      pr
    end

    it "shows the wait-elapsed badge instead of live" do
      visit users_pair_requests_path

      expect(page).to have_content("HHH")
      expect(page).to have_content("Wait time elapsed")
    end
  end

  context "when the request is already matched" do
    let!(:pair_request) do
      pr = create(:pair_request, :immediate, user: current_user, subject: "III", with_periods: false)
      create(:period, periodable: pr, start_at: Time.current)
      pr
    end

    before do
      create(:offer, :accepted, pair_request:)
      create(:session, sessionable: pair_request)
    end

    it "does not show a Keep waiting button" do
      visit users_pair_requests_path

      expect(page).to have_content("III")
      expect(page).not_to have_button("Keep waiting")
    end
  end
end
