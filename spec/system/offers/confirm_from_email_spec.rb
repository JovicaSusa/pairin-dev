RSpec.describe "poster accepts an offer from the email link", type: :system do
  let(:offerer) { create(:user, name: "Ada") }
  let(:offer) { create(:offer, offerer:, message: "Happy to pair on this!") }

  it "accepts without logging in" do
    visit offer_confirmation_path(token: offer.generate_token_for(:poster_confirmation))

    expect(page).to have_content("Ada wants to pair with you")
    expect(page).to have_content("Happy to pair on this!")

    click_button "Accept"

    expect(page).to have_content("You're pairing with Ada")
    expect(page).not_to have_button("Accept")
    expect(offer.reload).to be_accepted
  end
end
