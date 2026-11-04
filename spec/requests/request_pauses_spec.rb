require "rails_helper"

RSpec.describe "Pause this search", type: :request do
  let(:search) { create(:pair_request, subject: "Learn Rust together") }
  let(:token) { search.generate_token_for(:pause) }

  it "doesn't pause just from opening the link" do
    get request_pause_path(token:)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Learn Rust together", "Pause this search")
    expect(search.reload).not_to be_paused
  end

  it "pauses on POST, with no login" do
    post request_pause_path(token:)

    expect(search.reload).to be_paused
    follow_redirect!
    expect(response.body).to include("Your partner search is paused")
  end

  it "does nothing more when it's already off" do
    search.switch_off!
    at = search.reload.paused_at

    travel 1.day do
      post request_pause_path(token:)
    end

    expect(search.reload.paused_at).to eq(at)
  end

  it "refuses a tampered token, and the resume link's token" do
    post request_pause_path(token: "#{token}x")
    expect(response).to have_http_status(:not_found)

    post request_pause_path(token: search.generate_token_for(:resume))
    expect(response).to have_http_status(:not_found)

    expect(search.reload).not_to be_paused
  end

  it "keeps the token away from analytics" do
    get request_pause_path(token:)

    expect(response.body).not_to include("posthog")
  end

  [:offer_received_email, :offer_reminder_email].each do |email|
    it "is linked from the #{email}, for that search" do
      offer = create(:offer, pair_request: search)
      body = OfferMailer.with(offer:).public_send(email).body.encoded
      link_token = body[%r{/requests/pause/([^"\s]+)}, 1]

      expect(body).to include("Pause this search")
      expect(PairRequest.find_by_token_for(:pause, link_token)).to eq(search)
    end
  end
end
