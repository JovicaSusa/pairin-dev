RSpec.describe "update session call link", type: :system do
  let(:current_user) { create(:user) }

  let(:current_user_session) { create(:session, with_holder: false, sessionable: pair_request) }
  let!(:current_user_participation) do
    create(:participation, participable: current_user_session, participant: current_user)
  end
  let(:pair_request) { create(:pair_request, user: current_user, with_periods: false) }

  before { sign_in(current_user) }

  it "updates sesssion call link" do
    visit sessions_path

    fill_in :session_call_link, with: "www.something.com"
    click_button "Add"

    expect(page).to have_content("Call link successfuly added!")
  end
end
