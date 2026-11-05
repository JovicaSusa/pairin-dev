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

  it "goes from a proposal to partners, and keeps the chat open" do
    offer.post_message(poster, "Great to meet you")
    offer.propose_partnership!(by: applicant)
    sign_in(poster)
    visit conversation_path(offer)

    expect(page).to have_content("Sam wants to become partners.")
    expect(page).not_to have_button("Become partners")
    click_button "Accept"

    expect(page).to have_content("You and Sam")
    expect(page).to have_content(/workspace/i)
    expect(page).to have_field("Write a message")
    expect(offer.reload).to be_partners

    visit conversation_path(offer)

    expect(page).to have_content("You and Sam are partners.")
    expect(page).not_to have_button("Not a match")
  end

  it "proposes from the header and can be told not yet" do
    offer.post_message(poster, "Great to meet you")
    sign_in(applicant)
    visit conversation_path(offer)

    click_button "Become partners"

    expect(page).to have_content("You asked to become partners. Waiting for Maya")
    expect(page).to have_field("Write a message")
    expect(page).not_to have_button("Become partners")

    offer.decline_proposal!(by: poster)
    visit conversation_path(offer)

    expect(page).to have_content("Maya said not yet.")
    expect(page).to have_button("Become partners")
  end

  it "closes another chat on the search when a partnership forms" do
    other = create(:offer, pair_request: search, offerer: create(:user, name: "Lena"))
    other.post_message(poster, "Hi Lena")
    offer.post_message(poster, "Great to meet you")
    offer.propose_partnership!(by: applicant)
    offer.accept_proposal!(by: poster)

    sign_in(other.offerer)
    visit conversation_path(other)

    expect(page).to have_content(Partnership::CLOSING_MESSAGE)
    expect(page).to have_content("This search has found its partner, so this chat has ended.")
    expect(page).not_to have_field("Write a message")
    expect(page).not_to have_button("Become partners")
    expect(page).to have_content("Hi Lena")
  end

  it "sends on Enter, and starts a new line on Shift+Enter" do
    offer.post_message(poster, "Great to meet you")
    sign_in(poster)
    visit conversation_path(offer)

    field = find("textarea[aria-label='Write a message']")
    field.send_keys("First line", [:shift, :enter], "Second line")
    expect(field.value).to eq("First line\nSecond line")

    field.send_keys(:enter)

    expect(page).to have_content("Second line")
    expect(page).to have_field("Write a message", with: "")
    expect(offer.messages.last.body).to eq("First line\nSecond line")
  end

  it "doesn't send an empty message on Enter" do
    offer.post_message(poster, "Great to meet you")
    sign_in(poster)
    visit conversation_path(offer)

    expect { find("textarea[aria-label='Write a message']").send_keys(:enter); sleep 0.3 }.not_to change(Message, :count)
  end

  it "shows initials for someone with no photo" do
    sign_in(poster)
    visit conversations_path

    within("a[href='/conversations/#{offer.id}']") do
      expect(page).to have_content("S")
      expect(page).not_to have_css("img")
    end
  end

  it "highlights the right sidebar item on a search's applications" do
    sign_in(poster)
    visit pair_request_offers_path(search)

    expect(page).to have_button("Partner searches", class: "bg-purple/10")
    expect(page).not_to have_css("a.bg-purple", text: "Find a partner")

    visit pair_requests_path
    expect(page).to have_css("a.bg-purple", text: "Find a partner")
  end

  it "keeps the closing message at full strength in an ended chat" do
    other = create(:offer, pair_request: search, offerer: create(:user, name: "Lena"))
    other.post_message(poster, "Hi Lena")
    offer.post_message(poster, "Great to meet you")
    offer.propose_partnership!(by: applicant)
    offer.accept_proposal!(by: poster)
    sign_in(other.offerer)
    visit conversation_path(other)

    closing = find("p", text: Partnership::CLOSING_MESSAGE, match: :first)
    expect(page.evaluate_script("getComputedStyle(arguments[0].parentElement).opacity", closing)).to eq("1")
    expect(page).to have_css(".opacity-70", text: "Hi Lena")
  end

  it "reports someone from the thread" do
    sign_in(poster)
    visit conversation_path(offer)

    click_button "Report"
    click_button "Send report"
    expect(page).to have_content("Please say what happened")

    fill_in "What happened?", with: "They were rude"
    click_button "Send report"

    expect(page).to have_content("Thanks for telling us.")
    expect(page).not_to have_field("What happened?")
  end

  it "blocks after asking first" do
    sign_in(poster)
    visit conversation_path(offer)

    click_button "Block"
    expect(page).to have_content("Sam won't be told you blocked them.")
    click_button "Cancel"
    expect(page).not_to have_content("Sam won't be told you blocked them.")
    expect(Block.count).to eq(0)

    click_button "Block"
    within('[aria-label="Confirm block"]') { click_button "Block" }

    expect(page).to have_content("You've blocked Sam")
    expect(page).to have_content("You ended this conversation.")
    expect(Block.find_by(blocker: poster, blocked: applicant)).to be_present
  end

  it "shows the new navigation" do
    sign_in(poster)
    visit conversations_path

    expect(page).to have_link("Conversations")
    expect(page).to have_link("Partners")
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
