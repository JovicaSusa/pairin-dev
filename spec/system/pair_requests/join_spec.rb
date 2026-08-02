RSpec.describe "instant join a live pair request", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "when the live pair request doesn't require approval" do
    let!(:live_pair_request) do
      pair_request = create(:pair_request, :immediate, subject: "GGG", with_periods: false)
      create(:period, periodable: pair_request, start_at: Time.current)
      pair_request
    end

    it "joins the session immediately" do
      visit pair_requests_path

      click_button "Join"

      expect(page).to have_content("You're in! Happy pairin!")
    end
  end

  context "when the live pair request requires approval" do
    let!(:live_pair_request) do
      pair_request = create(:pair_request, :immediate, :requires_approval, subject: "GGG", with_periods: false)
      create(:period, periodable: pair_request, start_at: Time.current)
      pair_request
    end

    it "shows the Apply flow instead of a Join button" do
      visit pair_requests_path

      expect(page).to have_content("Apply")
      expect(page).not_to have_button("Join")
    end
  end
end
