RSpec.describe "cancel an unmatched immediate pair request", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "when the request hasn't been matched" do
    let!(:pair_request) do
      pr = create(:pair_request, :immediate, user: current_user, wait_minutes: 30, subject: "GGG", with_periods: false)
      create(:period, periodable: pr, start_at: Time.current)
      pr
    end

    it "soft-cancels it and shows the cancelled badge" do
      visit users_pair_requests_path

      expect(page).to have_content("GGG")

      accept_confirm do
        click_button "Cancel"
      end

      expect(page).to have_content("Request cancelled.")
      expect(page).to have_content("GGG")
      expect(page).to have_content("CANCELLED")
      expect(page).not_to have_button("Keep waiting")
      expect(pair_request.reload.cancelled_at).to be_present
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

    it "does not show a Cancel button" do
      visit users_pair_requests_path

      expect(page).to have_content("III")
      expect(page).not_to have_button("Cancel")
    end
  end
end
