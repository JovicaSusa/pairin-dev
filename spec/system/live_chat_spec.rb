# Runs a real socket through the app, so it swaps the test adapter for the
# in-process one for the length of each example.
RSpec.describe "live chat", type: :system do
  let(:poster) { create(:user, name: "Maya") }
  let(:applicant) { create(:user, name: "Sam") }
  let(:search) { create(:pair_request, user: poster) }
  let!(:offer) { create(:offer, pair_request: search, offerer: applicant, message: "Hi Maya!") }

  around do |example|
    server = ActionCable.server
    original = server.pubsub
    server.instance_variable_set(:@pubsub, ActionCable::SubscriptionAdapter::Async.new(server))
    example.run
  ensure
    server.instance_variable_set(:@pubsub, original)
  end

  # Waits for the socket's subscription, so a signal sent next can't be missed.
  def wait_until_listening
    expect(page).to have_css("body")
    Timeout.timeout(10) { sleep 0.1 until ActionCable.server.connections.any? { |c| c.subscriptions.identifiers.any? } }
  end

  before do
    offer.post_message(poster, "Great to meet you")
    offer.mark_read_by!(applicant)
  end

  it "shows a message to the other person without a reload, and keeps what they're typing" do
    sign_in(applicant)
    visit conversation_path(offer)
    fill_in "Write a message", with: "half-typed"
    wait_until_listening

    offer.post_message(poster, "Are you around on Tuesday?")

    expect(page).to have_content("Are you around on Tuesday?")
    expect(page).to have_field("Write a message", with: "half-typed")
  end

  it "updates the unread count live on other pages" do
    sign_in(applicant)
    visit activities_path
    expect(page).not_to have_css('[aria-label="1 unread"]')
    wait_until_listening

    offer.post_message(poster, "Are you around on Tuesday?")

    expect(page).to have_css('[aria-label="1 unread"]')
  end

  it "updates the Workspace's Chat tile live, without marking it read" do
    offer.propose_partnership!(by: applicant)
    partnership = offer.accept_proposal!(by: poster)
    offer.mark_read_by!(applicant)
    sign_in(applicant)
    visit partner_path(partnership)
    expect(page).to have_content("You're all caught up")
    wait_until_listening

    offer.post_message(poster, "Ping")

    expect(page).to have_content(/1\s+new message\b/)
    expect(page).to have_content("Maya: Ping")
    expect(offer.unread_messages_for(applicant).count).to eq(1)
  end

  it "shows a conversation ending live" do
    sign_in(applicant)
    visit conversation_path(offer)
    wait_until_listening

    offer.not_a_match!(by: poster)
    ConversationsChannel.notify(offer)

    expect(page).to have_content("This conversation has ended.")
    expect(page).not_to have_field("Write a message")
  end

  it "catches up on a missed message when the connection comes back" do
    sign_in(applicant)
    visit conversation_path(offer)
    wait_until_listening

    # The server drops the socket, and the message is sent while it's gone.
    connections = ActionCable.server.connections.dup
    offer.messages.create!(sender: poster, body: "Sent while you were away")
    connections.each(&:close)

    expect(page).to have_content("Sent while you were away", wait: 15)
  end
end
