RSpec.describe "editing a partner search", type: :system do
  let(:current_user) { create(:user) }
  let!(:pair_request) { create(:pair_request, user: current_user, subject: "Learn Rust", description: "Ownership") }

  before do
    create(:tagging, taggable: pair_request, tag: create(:tag, name: "rust"))
    sign_in(current_user)
  end

  it "changes the text, commitment and tags from the searches page" do
    visit users_pair_requests_path
    click_link "Edit"

    expect(page).to have_field("Subject", with: "Learn Rust")
    expect(page).to have_field("Description", with: "Ownership")

    fill_in "Subject", with: "Learn Go"
    fill_in "Description", with: "Goroutines and channels"
    select_option!("Commitment", "Open-ended")
    click_button "Remove tag"
    click_button "+ Add tag"
    find("input[placeholder='Search or create...']").fill_in(with: "go")
    click_button "Save changes"

    expect(page).to have_content("Partner search updated")
    expect(page).to have_content("Learn Go")
    expect(page).to have_content("Goroutines and channels")
    expect(page).to have_content("Partner · Open-ended")
    expect(pair_request.reload.tags.map(&:name)).to eq(["go"])
  end

  it "shows errors and keeps the search as it was" do
    visit edit_users_pair_request_path(pair_request)

    fill_in "Subject", with: ""
    click_button "Save changes"

    within(".pair_request_subject") do
      expect(page).to have_content("can't be blank")
    end
    expect(pair_request.reload.subject).to eq("Learn Rust")
  end
end
