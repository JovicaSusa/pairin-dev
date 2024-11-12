RSpec.describe "display users activities", type: :system do
  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  let!(:activity_1_for_current_user) { create(:activity, title: "Heyyy", receiver: current_user) }
  let!(:activity_2_for_current_user) { create(:activity, title: "Hoooo", receiver: current_user) }
  let!(:activity_for_other_user) { create(:activity, title: "Not me") }

  it "displays current users activities" do
    visit activities_path

    expect(page).to have_content("Heyyy")
    expect(page).to have_content("Hoooo")
    expect(page).not_to have_content("Not me")
  end
end
