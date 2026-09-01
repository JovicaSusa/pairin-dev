RSpec.describe "reschedule an unmatched immediate pair request", type: :system do
  let(:current_user) { create(:user) }

  let!(:pair_request) do
    pr = create(:pair_request, :immediate, user: current_user, wait_minutes: 15, subject: "GGG", with_periods: false)
    period = create(:period, periodable: pr, start_at: Time.current)
    period.update_column(:start_at, 30.minutes.ago)
    pr
  end

  before { sign_in(current_user) }

  it "flips the request to scheduled mode with the newly picked period" do
    visit users_pair_requests_path

    expect(page).to have_content("GGG")
    expect(page).to have_content("Wait time elapsed")

    click_button "Reschedule"
    pick_future_period!
    click_button "Confirm reschedule"

    expect(page).to have_content("Request rescheduled!")
    expect(page).to have_content("GGG")
    expect(page).not_to have_content("Wait time elapsed")
    expect(page).not_to have_button("Keep waiting")

    expect(pair_request.reload.mode).to eq("scheduled")
  end

  it "stays in immediate mode when no period is picked" do
    visit users_pair_requests_path

    click_button "Reschedule"
    click_button "Confirm reschedule"

    expect(page).to have_content("Wait time elapsed")
    expect(pair_request.reload.mode).to eq("immediate")
  end
end
