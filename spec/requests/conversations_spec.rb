require "rails_helper"

RSpec.describe "Conversations", type: :request do
  let(:poster) { create(:user, name: "Maya") }
  let(:applicant) { create(:user, name: "Sam") }
  let(:search) { create(:pair_request, user: poster) }
  let!(:offer) { create(:offer, pair_request: search, offerer: applicant, message: "Hi Maya!") }

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  def reply(body = "Great to meet you")
    post conversation_messages_path(offer), params: { message: { body: } }
  end

  describe "the application's message" do
    it "is the first message of the thread" do
      sign_in(poster)

      get conversation_path(offer)

      expect(props.dig("conversation", "messages").map { |m| m["body"] }).to eq(["Hi Maya!"])
    end
  end

  describe "before the poster replies" do
    it "doesn't let the applicant write more" do
      sign_in(applicant)

      expect { reply("One more thing") }.not_to change(Message, :count)

      expect(flash[:alert]).to be_present
      expect(offer.reload.replied_at).to be_nil
    end

    it "tells each person where they stand" do
      sign_in(applicant)
      get conversation_path(offer)
      expect(props["conversation"]).to include("status" => "Sent", "can_send" => false, "chat_open" => false)

      sign_in(poster)
      get conversation_path(offer)
      expect(props["conversation"]).to include("status" => "Reply", "can_send" => true, "chat_open" => false)
    end
  end

  describe "a late reply" do
    before { sign_in(poster) }

    it "still opens the chat and emails the applicant, after the search went Off" do
      search.switch_off!
      travel_to(offer.expires_at + 1.day)

      expect { reply }
        .to have_enqueued_mail(OfferMailer, :late_reply_email).with(params: { offer: }, args: []).once

      expect(offer.reload).to be_chat_open
      expect(search.reload).to be_paused
    end

    it "only sends that email for the first reply" do
      travel_to(offer.expires_at + 1.day)
      reply

      expect { reply("And another thing") }.not_to have_enqueued_mail(OfferMailer, :late_reply_email)
    end

    it "isn't sent for a reply in time" do
      expect { reply }.not_to have_enqueued_mail(OfferMailer, :late_reply_email)
    end

    it "isn't sent when the reply is refused" do
      travel_to(offer.expires_at + 1.day)

      expect { reply("") }.not_to have_enqueued_mail(OfferMailer, :late_reply_email)
      expect(offer.reload).to be_overdue
    end

    it "keeps a conversation that's open from timing out" do
      reply
      travel_to(offer.expires_at + 30.days)

      sign_in(poster)
      expect { reply("Still here") }.to change(offer.messages, :count).by(1)
      expect(offer.reload).to be_chat_open
    end
  end

  describe "scheduling the unread email" do
    it "checks 15 minutes after each message, for the other person" do
      sign_in(poster)

      freeze_time do
        expect { reply }
          .to have_enqueued_job(UnreadMessagesEmailJob).with(offer, applicant).at(15.minutes.from_now).once
      end
    end

    it "isn't scheduled by a new application, which has its own email" do
      expect { create(:offer, pair_request: search) }.not_to have_enqueued_job(UnreadMessagesEmailJob)
    end

    it "isn't scheduled by a late reply, which has its own email" do
      sign_in(poster)
      travel_to(offer.expires_at + 1.day)

      expect { reply }.not_to have_enqueued_job(UnreadMessagesEmailJob)
    end

    it "isn't scheduled by a refused message" do
      sign_in(applicant)

      expect { reply("Too soon") }.not_to have_enqueued_job(UnreadMessagesEmailJob)
    end
  end

  describe "the poster's first reply" do
    before do
      sign_in(poster)
      reply
    end

    it "opens the chat for both people, without any commitment" do
      expect(offer.reload).to be_chat_open
      expect(offer).not_to be_accepted

      sign_in(applicant)
      get conversation_path(offer)
      expect(props["conversation"]).to include("status" => "Talking", "can_send" => true, "chat_open" => true)
    end

    it "lets the applicant write back" do
      sign_in(applicant)

      expect { reply("Thanks!") }.to change(offer.messages, :count).by(1)
    end
  end

  it "keeps the first reply time when the poster writes again" do
    sign_in(poster)
    reply
    first = offer.reload.replied_at

    travel 1.hour do
      reply("And another thing")
    end

    expect(offer.reload.replied_at).to eq(first)
  end

  it "refuses an empty message and a very long one" do
    sign_in(poster)

    expect { reply("") }.not_to change(Message, :count)
    expect(session[:inertia_errors]).to include(:body)

    expect { reply("x" * (Message::MAX_LENGTH + 1)) }.not_to change(Message, :count)
    expect(offer.reload.replied_at).to be_nil
  end

  describe "who can read and write" do
    let(:stranger) { create(:user) }

    before { sign_in(stranger) }

    it "hides a thread from anyone else" do
      get conversation_path(offer)

      expect(response).to have_http_status(:not_found)
    end

    it "doesn't let anyone else write or end it" do
      expect { reply("Hello?") }.not_to change(Message, :count)
      expect(response).to have_http_status(:not_found)

      sign_in(stranger)
      post not_a_match_conversation_path(offer)
      expect(response).to have_http_status(:not_found)
      expect(offer.reload).not_to be_ended
    end

    it "doesn't list it" do
      get conversations_path

      expect(props["conversations"]).to be_empty
    end
  end

  describe "live signals and unread counts" do
    it "signals both people when someone writes" do
      sign_in(poster)

      expect { reply }
        .to have_broadcasted_to(applicant).from_channel(ConversationsChannel).with(conversation_id: offer.id)
        .and have_broadcasted_to(poster).from_channel(ConversationsChannel).with(conversation_id: offer.id)
    end

    it "signals both people when a conversation ends" do
      sign_in(poster)

      expect { post not_a_match_conversation_path(offer) }
        .to have_broadcasted_to(applicant).from_channel(ConversationsChannel)
    end

    it "signals the poster about a new application" do
      expect { create(:offer, pair_request: search) }
        .to have_broadcasted_to(poster).from_channel(ConversationsChannel)
    end

    it "counts the other person's unread messages, not your own" do
      sign_in(poster)
      get conversations_path

      expect(props["unreadMessages"]).to eq(1)
      expect(props["conversations"].first["unread"]).to eq(1)

      sign_in(applicant)
      get conversations_path

      expect(props["unreadMessages"]).to eq(0)
    end

    it "clears them when the conversation is opened, and counts new ones after" do
      sign_in(poster)
      get conversation_path(offer)

      expect(props["unreadMessages"]).to eq(0)
      expect(props["conversations"].first["unread"]).to eq(0)

      travel 1.minute do
        offer.messages.create!(sender: applicant, body: "One more")

        get conversations_path

        expect(props["unreadMessages"]).to eq(1)
      end
    end

    it "keeps each person's read position separate" do
      sign_in(applicant)
      get conversation_path(offer)

      sign_in(poster)
      get conversations_path

      expect(props["unreadMessages"]).to eq(1)
    end

    it "adds up across conversations, on any page" do
      create(:offer, pair_request: search)
      sign_in(poster)

      get activities_path

      expect(props["unreadMessages"]).to eq(2)
    end

    it "keeps other people's messages out of everyone else's count" do
      sign_in(create(:user))

      get conversations_path

      expect(props["unreadMessages"]).to eq(0)
    end
  end

  describe "the list" do
    it "shows each person the other, a status and the newest first" do
      older = create(:offer, pair_request: create(:pair_request, user: create(:user, name: "Tom")), offerer: applicant)
      older.update_columns(last_message_at: 1.day.ago)
      sign_in(applicant)

      get conversations_path

      expect(props["conversations"].map { |c| [c["id"], c.dig("other", "name"), c["status"]] }).to eq([
        [offer.id, "Maya", "Sent"], [older.id, "Tom", "Sent"]
      ])
    end

    it "moves a conversation up when someone writes" do
      older = create(:offer, pair_request: search)
      offer.update_columns(last_message_at: 1.day.ago)
      older.update_columns(last_message_at: 1.hour.ago)
      sign_in(poster)

      reply

      get conversations_path
      expect(props["conversations"].first).to include("id" => offer.id, "line" => "Great to meet you", "status" => "Talking")
    end
  end

  describe "Not a match" do
    before { sign_in(poster) }

    it "ends the conversation and tells the other person, keeping the reason private" do
      expect { post not_a_match_conversation_path(offer), params: { reason: "Different goals" } }
        .to have_enqueued_mail(OfferMailer, :not_a_match_email).with(params: { offer: }, args: []).once

      expect(offer.reload).to have_attributes(ended_by: poster, end_reason: "Different goals")
      expect(offer).to be_ended

      sign_in(applicant)
      get conversation_path(offer)
      expect(props["conversation"]).to include("status" => "Ended", "can_send" => false, "ended_by_viewer" => false)
      expect(response.body).not_to include("Different goals")
    end

    it "works without a reason, and from the applicant, before any reply" do
      sign_in(applicant)

      post not_a_match_conversation_path(offer)

      expect(offer.reload.ended_by).to eq(applicant)
      expect(offer.end_reason).to be_nil
    end

    it "stops both people writing" do
      post not_a_match_conversation_path(offer)

      expect { reply("Wait") }.not_to change(Message, :count)

      sign_in(applicant)
      expect { reply("Wait") }.not_to change(Message, :count)
    end

    it "only tells them once" do
      post not_a_match_conversation_path(offer)

      expect { post not_a_match_conversation_path(offer), params: { reason: "Changed" } }
        .not_to have_enqueued_mail(OfferMailer, :not_a_match_email)
      expect(offer.reload.end_reason).to be_nil
    end
  end

  describe "the old no-login Accept link" do
    it "goes to the inbox, through sign-in, and accepts nothing" do
      get "/offers/confirm/some-old-token"

      expect(response).to redirect_to("/conversations")
      expect(offer.reload.replied_at).to be_nil

      post "/offers/confirm/some-old-token"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "signing in from an emailed link" do
    it "returns the poster to the thread" do
      get conversation_path(offer)
      expect(response).to redirect_to(new_user_session_path)

      post user_session_path, params: { user: { email: poster.email, password: poster.password } }

      expect(response).to redirect_to(conversation_path(offer))
    end
  end
end
