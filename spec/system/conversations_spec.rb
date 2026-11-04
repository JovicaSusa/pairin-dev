RSpec.describe "conversations", type: :system do
  let(:poster) { create(:user, name: "Maya") }
  let(:applicant) { create(:user, name: "Sam", github_url: "https://github.com/sam", level: "competent") }
  let(:search) { create(:pair_request, user: poster, subject: "Python buddy", commitment: "open_ended") }
  let!(:offer) do
    create(:offer, pair_request: search, offerer: applicant, message: "Hi Maya!", goal: "Finish the course", how_often: "twice_a_week", how_long: "few_weeks")
  end

  it "lets the poster read the application, reply and keep talking" do
    sign_in(poster)
    visit conversations_path

    click_link "Sam"

    expect(page).to have_content("Finish the course")
    expect(page).to have_content("Twice a week")
    expect(page).to have_content("A few weeks")
    expect(page).to have_content("Open-ended")
    expect(page).to have_content("Competent")
    expect(page).to have_link("github.com/sam")
    expect(page).to have_content("Hi Maya!")

    fill_in "Write a message", with: "Great to meet you"
    click_button "Send"

    expect(page).to have_content("Great to meet you")
    expect(page).to have_field("Write a message", with: "")
    expect(page).not_to have_content("Finish the course")

    click_button "Show application"
    expect(page).to have_content("Finish the course")
  end

  it "makes the applicant wait for a reply" do
    sign_in(applicant)
    visit conversation_path(offer)

    expect(page).to have_content("You can write more once Maya replies.")
    expect(page).not_to have_field("Write a message")
    expect(page).to have_button("Not a match")
  end

  it "ends with Not a match and shows the thread read-only" do
    sign_in(poster)
    visit conversation_path(offer)

    click_button "Not a match"
    fill_in "Why? (optional, only we see this)", with: "Different goals"
    click_button "End conversation"

    expect(page).to have_content("You ended this conversation.")
    expect(page).not_to have_field("Write a message")
    expect(page).to have_content("Hi Maya!")
  end

  it "shows the new navigation" do
    sign_in(poster)
    visit conversations_path

    expect(page).to have_link("Conversations")
    expect(page).not_to have_link("Sessions")
    click_button "Partner searches"
    expect(page).to have_link("Opened")
    expect(page).not_to have_link("Applied")
  end

  it "opens a conversation from the poster's applications list" do
    sign_in(poster)
    visit pair_request_offers_path(search)

    click_link "Open conversation"

    expect(page).to have_content("Hi Maya!")
  end
end
