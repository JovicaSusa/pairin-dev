require 'rails_helper'

RSpec.describe "Offer confirmations", type: :request do
  let(:offerer) { create(:user, name: "Ada") }
  let(:offer) { create(:offer, offerer:, message: "Happy to pair on this!") }
  let(:token) { offer.generate_token_for(:poster_confirmation) }

  it "keeps the token away from analytics and link-preview metadata" do
    get offer_confirmation_path(token:)

    expect(response.body).not_to include("posthog")
    expect(response.body).not_to include('rel="canonical"')
    expect(response.body).not_to include("og:url")
    expect(response.body).to include('<meta name="robots" content="noindex, nofollow">')
  end

  describe "GET /offers/confirm/:token" do
    it "shows the offer without accepting it" do
      get offer_confirmation_path(token:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ada")
      expect(response.body).to include("Happy to pair on this!")
      expect(offer.reload).not_to be_accepted
      expect(Session.count).to eq(0)
    end
  end

  describe "the applicant's GitHub link" do
    it "is shown when they've added one" do
      offerer.update!(github_url: "https://github.com/ada")

      get offer_confirmation_path(token:)

      expect(response.body).to include('href="https://github.com/ada"')
    end

    it "is left out when they haven't" do
      get offer_confirmation_path(token:)

      expect(response.body).not_to include("GitHub:")
    end
  end

  describe "POST /offers/confirm/:token" do
    it "accepts the application and schedules no session" do
      expect { post offer_confirmation_path(token:) }.not_to change(Session, :count)

      expect(offer.reload).to be_accepted
      expect(response).to redirect_to(offer_confirmation_path(token:))
      follow_redirect!
      expect(response.body).to include("You accepted Ada's application")
    end
  end

  context "when the application has expired" do
    before { travel_to(offer.expires_at + 1.minute) }

    it "says so" do
      get offer_confirmation_path(token:)

      expect(response.body).to include("This application has expired")
      expect(response.body).not_to include(">Accept")
    end

    it "does not accept the offer" do
      post offer_confirmation_path(token:)

      expect(offer.reload).not_to be_accepted
      expect(Session.count).to eq(0)
    end
  end

  context "when another offer on the same request was already accepted" do
    before { create(:offer, :accepted, pair_request: offer.pair_request) }

    it "says the request is already matched" do
      get offer_confirmation_path(token:)

      expect(response.body).to include("This partner search is already matched")
      expect(response.body).not_to include(">Accept")
    end

    it "does not accept this offer" do
      post offer_confirmation_path(token:)

      expect(offer.reload).not_to be_accepted
    end
  end

  context "with a tampered or unknown token" do
    it "shows a not-found page" do
      get offer_confirmation_path(token: "#{token}x")

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("This link isn't valid")
    end

    it "does not accept anything" do
      post offer_confirmation_path(token: "nope")

      expect(response).to have_http_status(:not_found)
      expect(Offer.accepted.count).to eq(0)
    end
  end
end
