RSpec.describe "date of birth for existing users", type: :system do
  let(:user) { create(:user).tap { |u| u.update_columns(date_of_birth: nil) } }

  before { sign_in(user) }

  it "asks once, then carries on" do
    visit pair_requests_path

    expect(page).to have_content("Your date of birth")
    # On what's shown, because the page's data has timestamps that can contain "16".
    expect(page).not_to have_content(/\b16\b|minimum age/i)
    fill_in "Date of birth", with: Date.new(1990, 6, 15)
    click_button "Continue"

    expect(page).to have_content("Partner searches").or have_content("Pair Programming Requests")
    expect(user.reload.date_of_birth).to eq(Date.new(1990, 6, 15))
  end

  it "suspends an under-16 and shows the message" do
    visit pair_requests_path

    fill_in "Date of birth", with: 15.years.ago.to_date
    click_button "Continue"

    expect(page).to have_content("Your account is suspended")
    expect(user.reload).to be_suspended
  end
end
