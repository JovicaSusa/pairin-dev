RSpec.describe "create pair request offer", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  let!(:pair_request) { create(:pair_request, duration: 60) }

  it "creates offer for pair request" do
    visit pair_requests_path

    click_link "Apply"
    fill_in "Message", with: "Let's hack!"
    slot = pair_request.bookable_slots.second
    click_button "Pick a time"
    find('[role="option"]', text: "#{slot.start_at.strftime('%H:%M')}–#{slot.end_at.strftime('%H:%M')}", match: :first).click

    click_button "Apply"

    expect(page).to have_content("We've emailed the poster")
    expect(Offer.last.period.start_at).to eq(slot.start_at)
  end

  context "when details not provided" do
    it "displays errors" do
      visit pair_requests_path

      click_link "Apply"
      fill_in "Message", with: ""

      click_button "Apply"

      expect(page).to have_content("can't be blank")
    end
  end
end
