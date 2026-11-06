require "rails_helper"

RSpec.describe "Workspaces", type: :request do
  let(:poster) { create(:user, name: "Maya") }
  let(:partner) { create(:user, name: "Sam", github_url: "https://github.com/sam") }
  let(:search) { create(:pair_request, user: poster, subject: "Python buddy", commitment: "open_ended") }
  let!(:offer) { create(:offer, pair_request: search, offerer: partner, goal: "Finish the course", how_long: "few_weeks", message: "Hi Maya") }

  before do
    offer.post_message(poster, "Great to meet you")
    offer.propose_partnership!(by: partner)
  end

  let(:partnership) { offer.accept_proposal!(by: poster) }

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  it "opens when a partnership forms" do
    sign_in(poster)

    post accept_proposal_conversation_path(offer)

    expect(response).to redirect_to(partner_path(Partnership.last))
  end

  it "opens for the second person to propose too" do
    offer.decline_proposal!(by: poster)
    offer.propose_partnership!(by: poster)
    sign_in(partner)

    post propose_conversation_path(offer)

    expect(response).to redirect_to(partner_path(Partnership.last))
  end

  it "keeps the existing messages, and lets them keep talking" do
    sign_in(partner)
    get chat_partner_path(partnership)

    expect(props.dig("partnership", "conversation", "messages").map { |m| m["body"] }).to eq(["Hi Maya", "Great to meet you"])
    expect(props.dig("partnership", "conversation", "can_send")).to be(true)

    post conversation_messages_path(offer), params: { message: { body: "Thanks!" } }, headers: { "HTTP_REFERER" => chat_partner_url(partnership) }

    expect(response).to redirect_to(chat_partner_url(partnership))
    expect(offer.messages.last.body).to eq("Thanks!")
  end

  it "shows the partner and what each person committed to" do
    sign_in(poster)
    get partner_path(partnership)

    expect(props["partnership"]).to include("your_commitment" => "Open-ended", "partner_commitment" => "A few weeks")
    expect(props.dig("partnership", "conversation", "other")).to include("name" => "Sam")

    sign_in(partner)
    get partner_path(partnership)

    expect(props["partnership"]).to include("your_commitment" => "A few weeks", "partner_commitment" => "Open-ended")
  end

  describe "the overview" do
    it "says how many messages are new and shows the last one, without marking them read" do
      offer.mark_read_by!(poster)
      offer.post_message(partner, "Are you there?")
      offer.post_message(partner, "Hello?")
      sign_in(poster)

      get partner_path(partnership)

      expect(props["partnership"]).to include("unread" => 2, "last_message" => { "body" => "Hello?", "mine" => false })
      expect(props["unreadMessages"]).to eq(2)
      expect(props.dig("partnership", "conversation")).not_to have_key("messages")
    end

    it "counts nothing new once the chat is opened" do
      offer.post_message(partner, "Are you there?")
      sign_in(poster)

      get chat_partner_path(partnership)
      get partner_path(partnership)

      expect(props["partnership"]).to include("unread" => 0)
      expect(props["unreadMessages"]).to eq(0)
    end

    it "leaves Pairin's own messages out of the last message" do
      sign_in(partner)
      partnership
      offer.messages.create!(sender: nil, body: "You're now partners")

      get partner_path(partnership)

      expect(props.dig("partnership", "last_message", "body")).to eq("Great to meet you")
    end

    it "shows the check-in weeks" do
      sign_in(poster)
      travel_to(partnership.created_at + 7.days + 1.minute) do
        CheckIn.create!(partnership:, user: partner, week: 1).answer!(true)

        get partner_path(partnership)

        expect(props.dig("partnership", "weeks")).to eq([{ "week" => 1, "worked_together" => true }])
      end
    end
  end

  describe "the Chat page" do
    it "marks the chat read when opened" do
      offer.post_message(partner, "Are you there?")
      sign_in(poster)

      get chat_partner_path(partnership)

      expect(props["unreadMessages"]).to eq(0)
      expect(props.dig("partnership", "conversation", "messages").last["body"]).to eq("Are you there?")
    end

    it "is only for the two partners" do
      sign_in(create(:user))

      get chat_partner_path(partnership)

      expect(response).to have_http_status(:not_found)
    end

    it "needs sign-in" do
      get chat_partner_path(partnership)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "the goal" do
    it "is prefilled from the application" do
      expect(partnership.goal).to eq("Finish the course")
    end

    it "falls back to the search when the application has none" do
      offer.update_columns(goal: nil)

      expect(offer.accept_proposal!(by: poster).goal).to eq("Python buddy")
    end

    it "can be edited by either person" do
      sign_in(partner)
      patch partner_path(partnership), params: { goal: "Build a scraper" }
      expect(partnership.reload.goal).to eq("Build a scraper")

      sign_in(poster)
      patch partner_path(partnership), params: { goal: "Build two scrapers" }
      expect(partnership.reload.goal).to eq("Build two scrapers")
    end

    it "is optional: either person can clear it" do
      sign_in(poster)

      patch partner_path(partnership), params: { goal: "   " }

      expect(partnership.reload.goal).to be_nil
      expect(response).to redirect_to(partner_path(partnership))
    end

    it "signals the other person" do
      sign_in(poster)

      expect { patch partner_path(partnership), params: { goal: "New" } }
        .to have_broadcasted_to(partner).from_channel(ConversationsChannel)
    end

    it "refuses one that's too long" do
      sign_in(poster)

      patch partner_path(partnership), params: { goal: "x" * (Partnership::GOAL_MAX_LENGTH + 1) }

      expect(partnership.reload.goal).to eq("Finish the course")
      expect(session[:inertia_errors]).to include(:goal)
    end
  end

  describe "who can open it" do
    before { sign_in(create(:user)) }

    it "is only the two partners" do
      get partner_path(partnership)
      expect(response).to have_http_status(:not_found)
    end

    it "doesn't let anyone else change the goal" do
      patch partner_path(partnership), params: { goal: "Hacked" }

      expect(response).to have_http_status(:not_found)
      expect(partnership.reload.goal).to eq("Finish the course")
    end

    it "doesn't list it for them" do
      partnership
      get partners_path

      expect(props["partnerships"]).to be_empty
    end
  end

  it "needs sign-in" do
    get partner_path(partnership)

    expect(response).to redirect_to(new_user_session_path)
  end

  describe "the Partners page" do
    it "lists each partnership, with the other person" do
      partnership
      sign_in(poster)

      get partners_path

      expect(props["partnerships"].first).to include("id" => partnership.id, "goal" => "Finish the course", "ended" => false)
      expect(props["partnerships"].first["partner"]).to include("name" => "Sam")
    end

    it "shows only an under-18 partner's name" do
      minor_poster = create(:user, date_of_birth: 17.years.ago.to_date)
      minor = create(:user, name: "Mia", date_of_birth: 17.years.ago.to_date, github_url: "https://github.com/mia", profession: "Student")
      minors_offer = create(:offer, pair_request: create(:pair_request, user: minor_poster), offerer: minor)
      minors_offer.post_message(minor_poster, "Hi")
      minors_offer.propose_partnership!(by: minor)
      together = minors_offer.accept_proposal!(by: minor_poster)
      sign_in(minor_poster)

      get partner_path(together)

      expect(props.dig("partnership", "conversation", "other")).to eq("name" => "Mia", "image_url" => nil)
      expect(response.body).not_to include("github.com/mia")

      get chat_partner_path(together)

      expect(props.dig("partnership", "conversation", "other")).to include("name" => "Mia", "image_url" => nil, "github_url" => nil, "level" => nil)
      expect(response.body).not_to include("github.com/mia")
    end
  end

  describe "blocking from the Workspace" do
    before do
      partnership
      sign_in(poster)
    end

    it "ends the partnership and the chat, keeps the record and says nothing about the block" do
      post block_conversation_path(offer), headers: { "HTTP_REFERER" => partner_url(partnership) }

      expect(response).to redirect_to(partner_url(partnership))
      expect(partnership.reload).to be_ended
      expect(partnership.ended_by).to eq(poster)
      expect(offer.reload).to be_ended

      follow_redirect!
      sign_in(partner)
      get partner_path(partnership)

      expect(props["partnership"]).to include("ended" => true)
      expect(response.body).not_to match(/blocked/i)

      get chat_partner_path(partnership)

      expect(props.dig("partnership", "conversation", "can_send")).to be(false)
      expect(response.body).not_to match(/blocked/i)
    end

    it "makes it read-only" do
      post block_conversation_path(offer)

      patch partner_path(partnership), params: { goal: "Changed" }

      expect(partnership.reload.goal).to eq("Finish the course")
      expect(flash[:alert]).to include("ended")
    end
  end

  it "can be reported from the Workspace, and returns there" do
    partnership
    sign_in(poster)

    expect { post report_conversation_path(offer), params: { reason: "Rude" }, headers: { "HTTP_REFERER" => partner_url(partnership) } }
      .to have_enqueued_mail(ReportMailer, :chat_report).once

    expect(response).to redirect_to(partner_url(partnership))
  end

  it "doesn't let Not a match end a partnership" do
    partnership
    sign_in(poster)

    post not_a_match_conversation_path(offer)

    expect(offer.reload).not_to be_ended
    expect(partnership.reload).not_to be_ended
  end

  it "is deleted with either person's account" do
    partnership

    expect { partner.destroy! }.to change(Partnership, :count).by(-1)
  end
end
