RSpec.describe "users sessions", type: :system do
  let(:current_user) { create(:user) }

  let(:current_user_session) { create(:session) }
  let(:other_user_session) { create(:session) }
  let!(:current_user_participation) do
    create(:participation, participable: current_user_session, participant: current_user)
  end
  let!(:other_user_participation) { create(:participation, participable: other_user_session) }

  before { sign_in(current_user) }

  it "displays users sesssion" do
    visit sessions_path

    expect(page).to have_content(current_user_session.sessionable.subject)
    expect(page).not_to have_content(other_user_session.sessionable.subject)
  end
end
