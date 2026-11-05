require "rails_helper"

RSpec.describe "Ending a partnership", type: :request do
  let(:poster) { create(:user, name: "Maya", email: "maya@example.com") }
  let(:partner) { create(:user, name: "Sam", email: "sam@example.com") }
  let(:search) { create(:pair_request, user: poster, subject: "Python buddy") }
  let!(:offer) { create(:offer, pair_request: search, offerer: partner) }
  let!(:partnership) do
    offer.post_message(poster, "Hi")
    offer.propose_partnership!(by: partner)
    offer.accept_proposal!(by: poster)
  end

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  def end_it(params = {}) = post(end_partnership_partner_path(partnership), params:)

  it "works for either partner, and keeps the record for metrics" do
    sign_in(partner)

    end_it

    expect(partnership.reload).to have_attributes(ended_by: partner, end_reason: nil)
    expect(partnership).to be_ended
    expect(Partnership.exists?(partnership.id)).to be(true)
    expect(response).to redirect_to(partner_path(partnership))
  end

  it "keeps an optional reason private" do
    sign_in(poster)

    end_it(reason: "Different goals")

    expect(partnership.reload.end_reason).to eq("Different goals")
    expect(OfferMailer.with(offer:, ended_by: poster).partnership_ended_email.body.encoded).not_to include("Different goals")

    follow_redirect!
    sign_in(partner)
    get partner_path(partnership)
    expect(response.body).not_to include("Different goals")
  end

  it "tells the other person by email, once, and live in the app" do
    sign_in(poster)

    expect { end_it }
      .to have_enqueued_mail(OfferMailer, :partnership_ended_email).with(params: { offer:, ended_by: poster }, args: []).once
      .and have_broadcasted_to(partner).from_channel(ConversationsChannel)

    mail = OfferMailer.with(offer:, ended_by: poster).partnership_ended_email
    expect(mail.to).to eq(["sam@example.com"])
    expect(mail.body.encoded).to include("Maya has ended your partnership")
    expect(mail.body.encoded).not_to include("maya@example.com")

    expect { end_it }.not_to have_enqueued_mail(OfferMailer, :partnership_ended_email)
  end

  it "makes the Workspace read-only for both" do
    sign_in(poster)
    end_it

    follow_redirect!
    expect(props["partnership"]).to include("ended" => true, "ended_by_viewer" => true)
    expect(props.dig("partnership", "conversation", "can_send")).to be(false)

    sign_in(partner)
    get partner_path(partnership)
    expect(props["partnership"]).to include("ended" => true, "ended_by_viewer" => false)

    expect { post conversation_messages_path(offer), params: { message: { body: "Wait" } } }.not_to change(Message, :count)

    patch partner_path(partnership), params: { goal: "Changed" }
    expect(partnership.reload.goal).not_to eq("Changed")
  end

  it "shows as ended on the Partners page" do
    sign_in(partner)
    end_it

    get partners_path

    expect(props["partnerships"].first).to include("ended" => true)
  end

  it "keeps the search Off" do
    sign_in(poster)
    end_it

    expect(search.reload).to be_paused
    expect(search.switch_on!).to be(false)
  end

  it "tells a blocked partner only that it ended" do
    sign_in(poster)

    expect { post block_conversation_path(offer) }
      .to have_enqueued_mail(OfferMailer, :partnership_ended_email).with(params: { offer:, ended_by: poster }, args: []).once

    expect(OfferMailer.with(offer:, ended_by: poster).partnership_ended_email.body.encoded).not_to match(/blocked|blocking/i)
  end

  it "can't be done from outside it" do
    sign_in(create(:user))

    end_it

    expect(response).to have_http_status(:not_found)
    expect(partnership.reload).not_to be_ended
  end

  it "doesn't lose the goal when the goal is missing from an update" do
    sign_in(poster)

    patch partner_path(partnership), params: {}

    expect(partnership.reload.goal).to be_present
  end

  it "sends a refused message back to the Workspace it came from" do
    sign_in(poster)
    end_it

    post conversation_messages_path(offer), params: { message: { body: "Wait" } }, headers: { "HTTP_REFERER" => partner_url(partnership) }

    expect(response).to redirect_to(partner_url(partnership))
  end
end
