require "rails_helper"

RSpec.describe "When a partnership forms", type: :request do
  let(:poster) { create(:user, name: "Maya") }
  let(:partner) { create(:user, name: "Sam") }
  let(:search) { create(:pair_request, user: poster) }
  let!(:offer) { create(:offer, pair_request: search, offerer: partner) }

  let!(:talking) { create(:offer, pair_request: search).tap { |o| o.post_message(poster, "Hi") } }
  let!(:waiting) { create(:offer, pair_request: search) }
  let!(:elsewhere) { create(:offer, offerer: waiting.offerer) }

  around do |example|
    Rails.configuration.x.send_suggestion_emails = true
    example.run
  ensure
    Rails.configuration.x.send_suggestion_emails = false
  end

  before do
    offer.post_message(poster, "Great to meet you")
    offer.propose_partnership!(by: partner)
    sign_in(poster)
  end

  def form = post(accept_proposal_conversation_path(offer))

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  it "switches the search Off and keeps the partners talking" do
    form

    expect(search.reload).to be_paused
    expect(offer.reload).to be_chat_open
    expect(offer).to be_partners
    expect(offer.messages.pluck(:body)).not_to include(Partnership::CLOSING_MESSAGE)
  end

  describe "an unanswered application" do
    it "ends, and the applicant gets the polite email with open searches" do
      expect { form }
        .to have_enqueued_mail(OfferMailer, :search_filled_email).with(params: { offer: waiting }, args: []).once

      expect(waiting.reload).to be_ended
      expect(waiting.messages.pluck(:body)).not_to include(Partnership::CLOSING_MESSAGE)
    end

    it "doesn't email someone who was already told the poster went quiet" do
      waiting.update_columns(expiry_notified_at: 1.day.ago)

      expect { form }.not_to have_enqueued_mail(OfferMailer, :search_filled_email)
      expect(waiting.reload).to be_ended
    end

    it "holds the email back while suggestion emails are off" do
      Rails.configuration.x.send_suggestion_emails = false

      expect { form }.not_to have_enqueued_mail(OfferMailer, :search_filled_email)
      expect(waiting.reload).to be_ended
    end
  end

  describe "another open chat" do
    before { form }

    it "gets a closing message and becomes read-only for both" do
      expect(talking.reload).to be_ended
      expect(talking.messages.order(:created_at).last).to have_attributes(sender: nil, body: Partnership::CLOSING_MESSAGE)

      sign_in(talking.offerer)
      expect { post conversation_messages_path(talking), params: { message: { body: "Wait" } } }.not_to change(Message, :count)

      get conversation_path(talking)
      expect(props["conversation"]).to include("status" => "Ended", "search_filled" => true, "can_send" => false, "can_propose" => false)
      expect(props.dig("conversation", "messages").last).to include("from_pairin" => true, "mine" => false)
    end

    it "doesn't get the polite email, and doesn't count the closing message as unread" do
      sign_in(talking.offerer)
      get conversation_path(talking)

      expect(props["unreadMessages"]).to eq(0)
    end


    it "shows the partners' own chat as not filled" do
      get conversation_path(offer)

      expect(props["conversation"]).to include("status" => "Partners", "search_filled" => false, "can_send" => true)
    end
  end

  it "ends another chat's pending proposal" do
    talking.propose_partnership!(by: talking.offerer)

    form

    expect(talking.reload).not_to be_proposal_pending
    expect(talking.accept_proposal!(by: poster)).to be_nil
  end

  it "leaves applications on other searches alone" do
    form

    expect(elsewhere.reload).not_to be_ended
    expect(elsewhere.pair_request.reload).not_to be_paused
  end

  it "leaves earlier ended conversations as they were" do
    ended = create(:offer, pair_request: search)
    ended.not_a_match!(by: poster)
    at = ended.reload.ended_at

    form

    expect(ended.reload.ended_at).to eq(at)
    expect(ended.ended_by).to eq(poster)
  end

  it "stays Off: it can't be switched back on" do
    form

    patch resume_users_pair_request_path(search)

    expect(search.reload).to be_paused
    expect(flash[:alert]).to include("found its partner")
  end

  it "stays Off from the no-login link too" do
    form
    token = search.generate_token_for(:resume)

    post request_resumption_path(token:)
    expect(search.reload).to be_paused

    follow_redirect!
    expect(response.body).to include("found its partner")
    expect(response.body).not_to include(">Turn it back on")
  end

  it "stops the 72-hour clock for applications it ended" do
    form
    travel_to(waiting.expires_at + 1.minute)

    expect { OfferExpiryJob.perform_now(waiting) }.not_to have_enqueued_mail(PairRequestMailer, :request_paused_email)
  end

  it "shows a report of a closed chat with the closing message" do
    form

    body = ReportMailer.with(offer: talking, reporter: poster, reason: "Rude").chat_report.body.encoded

    expect(body).to include("Pairin")
    expect(body).to include("found its partner")
  end

  describe "the polite email" do
    it "says the search is taken and points to open searches, and names no one" do
      open_search = create(:pair_request, subject: "Learn Go together")

      mail = OfferMailer.with(offer: waiting).search_filled_email

      expect(mail.to).to eq([waiting.offerer.email])
      expect(mail.body.encoded).to include("found its partner")
      expect(mail.body.encoded).to include("Learn Go together")
      expect(mail.body.encoded).to include(new_pair_request_offer_path(open_search))
      expect(mail.body.encoded).not_to include("Sam")
    end
  end
end
