require "rails_helper"

RSpec.describe "Proposing a partnership", type: :request do
  let(:poster) { create(:user, name: "Maya") }
  let(:applicant) { create(:user, name: "Sam") }
  let(:search) { create(:pair_request, user: poster) }
  let!(:offer) { create(:offer, pair_request: search, offerer: applicant) }

  before do
    offer.post_message(poster, "Great to meet you")
    sign_in(applicant)
  end

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  def conversation_as(user)
    sign_in(user)
    get conversation_path(offer)
    props["conversation"]
  end

  describe "proposing" do
    it "works from either side, emails the other person and signals both" do
      expect { post propose_conversation_path(offer) }
        .to have_enqueued_mail(OfferMailer, :proposal_email).with(params: { offer: }, args: []).once
        .and have_broadcasted_to(poster).from_channel(ConversationsChannel)

      expect(offer.reload).to have_attributes(proposed_by: applicant)
      expect(OfferMailer.with(offer:).proposal_email.to).to eq([poster.email])

      offer.update_columns(proposed_at: nil, proposed_by_id: nil)
      sign_in(poster)
      post propose_conversation_path(offer)

      expect(offer.reload).to have_attributes(proposed_by: poster)
      expect(OfferMailer.with(offer:).proposal_email.to).to eq([applicant.email])
    end

    it "shows each person their side, and hides the button while it's pending" do
      expect(conversation_as(applicant)).to include("can_propose" => true, "proposal" => nil)

      post propose_conversation_path(offer)

      expect(conversation_as(applicant)).to include("can_propose" => false, "proposal" => "waiting", "can_send" => true)
      expect(conversation_as(poster)).to include("can_propose" => false, "proposal" => "incoming", "can_send" => true)
    end

    it "doesn't send a second email for a second click" do
      post propose_conversation_path(offer)

      expect { post propose_conversation_path(offer) }.not_to have_enqueued_mail(OfferMailer, :proposal_email)
    end

    it "accepts instead when the other person proposed at the same moment" do
      post propose_conversation_path(offer)
      sign_in(poster)

      expect { post propose_conversation_path(offer) }.to change(Partnership, :count).by(1)
    end

    it "schedules one reminder, for 3 days later" do
      freeze_time do
        expect { post propose_conversation_path(offer) }
          .to have_enqueued_job(ProposalReminderJob).at(3.days.from_now).once
      end
    end

    it "needs an open chat" do
      unanswered = create(:offer, pair_request: create(:pair_request, user: poster), offerer: applicant)

      post propose_conversation_path(unanswered)
      expect(unanswered.reload.proposed_at).to be_nil

      offer.not_a_match!(by: poster)
      post propose_conversation_path(offer)
      expect(offer.reload.proposed_at).to be_nil
    end

    it "can't be used from outside the conversation" do
      sign_in(create(:user))

      post propose_conversation_path(offer)

      expect(response).to have_http_status(:not_found)
      expect(offer.reload.proposed_at).to be_nil
    end
  end

  describe "accepting" do
    before { post propose_conversation_path(offer) }

    it "forms a partnership for that search, and tells the proposer" do
      sign_in(poster)

      expect { post accept_proposal_conversation_path(offer) }
        .to change(Partnership, :count).by(1)
        .and have_enqueued_mail(OfferMailer, :proposal_accepted_email).with(params: { offer:, recipient: applicant }, args: []).once

      expect(Partnership.last).to have_attributes(offer:, pair_request: search)
      expect(offer.reload).to be_partners
      expect(conversation_as(applicant)).to include("status" => "Partners", "partners" => true, "can_send" => true, "can_propose" => false)
    end

    it "isn't something the proposer can do themselves" do
      expect { post accept_proposal_conversation_path(offer) }.not_to change(Partnership, :count)

      expect(flash[:alert]).to be_present
    end

    it "can't happen twice" do
      sign_in(poster)
      post accept_proposal_conversation_path(offer)

      expect { post accept_proposal_conversation_path(offer) }.not_to change(Partnership, :count)
    end

    it "keeps a search to one partnership" do
      other = create(:offer, pair_request: search)
      other.post_message(poster, "Hi")
      other.propose_partnership!(by: other.offerer)
      sign_in(poster)
      post accept_proposal_conversation_path(offer)

      expect { post accept_proposal_conversation_path(other) }.not_to change(Partnership, :count)
      expect(other.reload).not_to be_partners
    end

    it "does nothing once the conversation has ended" do
      offer.not_a_match!(by: applicant)
      sign_in(poster)

      expect { post accept_proposal_conversation_path(offer) }.not_to change(Partnership, :count)
    end

    it "is done in the app only: the email has no answer links" do
      body = OfferMailer.with(offer: offer.reload).proposal_email.body.encoded

      expect(body).to include("/conversations/#{offer.id}")
      expect(body).not_to include("accept_proposal")
    end
  end

  describe "declining" do
    before do
      post propose_conversation_path(offer)
      sign_in(poster)
    end

    it "leaves the chat open, tells the proposer, and lets either person ask again" do
      expect { post decline_proposal_conversation_path(offer) }.not_to change(Partnership, :count)

      expect(offer.reload).to be_chat_open
      expect(conversation_as(applicant)).to include("proposal" => "declined", "can_propose" => true, "can_send" => true)
      expect(conversation_as(poster)).to include("proposal" => nil, "can_propose" => true)

      sign_in(applicant)
      post propose_conversation_path(offer)
      expect(conversation_as(applicant)).to include("proposal" => "waiting")
    end

    it "isn't something the proposer can do" do
      sign_in(applicant)
      post decline_proposal_conversation_path(offer)

      expect(offer.reload).to be_proposal_pending
    end
  end

  describe "the reminder" do
    def remind = ProposalReminderJob.perform_now(offer, @proposed_at)

    before do
      post propose_conversation_path(offer)
      @proposed_at = offer.reload.proposed_at
    end

    it "emails the other person when it's still unanswered, and the chat stays open" do
      expect { remind }.to have_enqueued_mail(OfferMailer, :proposal_reminder_email).once

      expect(offer.reload).to be_chat_open
      expect(OfferMailer.with(offer:).proposal_reminder_email.to).to eq([poster.email])
    end

    it "stays quiet after an answer" do
      offer.accept_proposal!(by: poster)

      expect { remind }.not_to have_enqueued_mail(OfferMailer, :proposal_reminder_email)
    end

    it "stays quiet after a decline" do
      offer.decline_proposal!(by: poster)

      expect { remind }.not_to have_enqueued_mail(OfferMailer, :proposal_reminder_email)
    end

    it "stays quiet about an old proposal when a new one was made" do
      offer.decline_proposal!(by: poster)
      travel 1.minute
      offer.propose_partnership!(by: applicant)

      expect { remind }.not_to have_enqueued_mail(OfferMailer, :proposal_reminder_email)
    end

    it "stays quiet once the conversation has ended" do
      offer.not_a_match!(by: poster)

      expect { remind }.not_to have_enqueued_mail(OfferMailer, :proposal_reminder_email)
    end
  end

  it "is deleted with the account that's in it" do
    post propose_conversation_path(offer)
    offer.accept_proposal!(by: poster)

    expect { applicant.destroy! }.to change(Partnership, :count).by(-1)
  end
end
