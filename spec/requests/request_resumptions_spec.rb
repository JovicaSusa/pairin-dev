require 'rails_helper'

RSpec.describe "Request resumptions", type: :request do
  let(:pair_request) { create(:pair_request, subject: "Learn Rust together", paused_at: 1.hour.ago) }
  let(:token) { pair_request.generate_token_for(:resume) }

  it "keeps the token away from analytics and link-preview metadata" do
    get request_resumption_path(token:)

    expect(response.body).not_to include("posthog")
    expect(response.body).not_to include('rel="canonical"')
    expect(response.body).not_to include("og:url")
    expect(response.body).to include('<meta name="robots" content="noindex, nofollow">')
  end

  describe "GET /requests/resume/:token" do
    it "shows the paused request without switching it on" do
      get request_resumption_path(token:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Learn Rust together")
      expect(response.body).to include("Turn it back on")
      expect(pair_request.reload).to be_paused
    end
  end

  describe "POST /requests/resume/:token" do
    let(:expired_offer) { create(:offer, pair_request:) }

    before { travel_to(expired_offer.period.start_at + 1.minute) }

    it "switches the request back on and leaves expired offers expired" do
      post request_resumption_path(token:)

      expect(pair_request.reload).not_to be_paused
      expect(expired_offer.reload.status).to eq("EXPIRED")
      expect(response).to redirect_to(request_resumption_path(token:))
      follow_redirect!
      expect(response.body).to include("Your request is back on")
    end
  end

  context "when the poster has no weekly hours" do
    before { pair_request.user.availability_windows.destroy_all }

    it "keeps the request off and points to weekly hours" do
      post request_resumption_path(token:)

      expect(pair_request.reload).to be_paused
      follow_redirect!
      expect(response.body).to include("Add your weekly hours")
      expect(response.body).to include(availability_path)
    end
  end

  context "when the request is already on" do
    before { pair_request.update!(paused_at: nil) }

    it "says so and offers no button" do
      get request_resumption_path(token:)

      expect(response.body).to include("Your request is back on")
      expect(response.body).not_to include(">Turn it back on")
    end
  end

  context "with a tampered or unknown token" do
    it "shows a not-found page" do
      get request_resumption_path(token: "#{token}x")

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("This link isn't valid")
    end

    it "switches nothing on" do
      post request_resumption_path(token: "nope")

      expect(response).to have_http_status(:not_found)
      expect(pair_request.reload).to be_paused
    end
  end
end
