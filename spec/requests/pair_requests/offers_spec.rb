require 'rails_helper'

RSpec.describe "PairRequests::Offers", type: :request do
  # Monday 2 Nov 2026, 08:00 UTC.
  around { |example| travel_to(Time.utc(2026, 11, 2, 8, 0)) { example.run } }

  let(:offerer) { create(:user) }
  let(:pair_request) { create(:pair_request) }

  before { sign_in(offerer) }

  describe "GET /pair_requests/:pair_request_id/offers" do
    it "sends the poster each applicant's GitHub link" do
      offerer.update!(github_url: "https://github.com/ada")
      create(:offer, pair_request:, offerer:)
      sign_in(pair_request.user)

      get pair_request_offers_path(pair_request)

      props = JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
      expect(props["offers"].first.dig("offerer", "github_url")).to eq("https://github.com/ada")
    end
  end

  describe "GET /users/offers" do
    it "lists the applicant's applications, with an old one's time and without a time on a new one" do
      old = create(:offer, offerer:, with_old_period: true)
      new_offer = create(:offer, offerer:)

      travel 3.days

      get users_offers_path

      offers = JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"]).dig("props", "offers")
      expect(offers.find { |o| o["id"] == old.id }["start_at"]).to be_present
      expect(offers.find { |o| o["id"] == new_offer.id }["start_at"]).to be_nil
    end
  end

  describe "GET /pair_requests/:pair_request_id/offers/new" do
    it "asks for no time" do
      get new_pair_request_offer_path(pair_request)

      props = JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
      expect(props).not_to include("slots")
    end
  end

  describe "POST /pair_requests/:pair_request_id/offers" do
    def post_offer
      post pair_request_offers_path(pair_request), params: { offer: { message: "Let's pair!" } }
    end

    it "saves the application with no time, and schedules no session" do
      expect { post_offer }
        .to change(Offer, :count).by(1)
        .and not_change(Period, :count)
        .and not_change(Session, :count)

      expect(Offer.last.period).to be_nil
    end

    it "ignores a time sent anyway" do
      post pair_request_offers_path(pair_request), params: { offer: { message: "Let's pair!", start_at: 1.day.from_now.iso8601 } }

      expect(Offer.last.period).to be_nil
    end

    it "emails the request's poster about the offer" do
      expect { post_offer }
        .to have_enqueued_mail(OfferMailer, :offer_received_email)
        .with(params: { offer: an_instance_of(Offer) }, args: [])
        .exactly(:once)
    end

    it "tells the offerer the poster has been emailed" do
      post_offer

      expect(flash[:notice]).to include("emailed")
    end

    it "needs a message" do
      expect { post pair_request_offers_path(pair_request), params: { offer: { message: "" } } }
        .to not_change(Offer, :count)
        .and not_have_enqueued_job(OfferExpiryJob)

      expect(session[:inertia_errors]).to include(:message)
    end

    context "when the request is switched off" do
      before { pair_request.update!(paused_at: 1.hour.ago) }

      it "rejects the offer with a clear message and emails nobody" do
        expect { post_offer }
          .to not_change(Offer, :count)
          .and not_have_enqueued_mail(OfferMailer, :offer_received_email)

        expect(response).to redirect_to(pair_requests_path)
        expect(flash[:alert]).to eq("This partner search is switched off and isn't taking applications right now.")
      end

      it "doesn't show the offer form either" do
        get new_pair_request_offer_path(pair_request)

        expect(response).to redirect_to(pair_requests_path)
        expect(flash[:alert]).to eq("This partner search is switched off and isn't taking applications right now.")
      end
    end

    it "checks for an answer 72 hours later" do
      expect { post_offer }
        .to have_enqueued_job(OfferExpiryJob).with(an_instance_of(Offer)).at(72.hours.from_now).exactly(:once)
    end

    it "reminds the poster 24 hours later" do
      expect { post_offer }
        .to have_enqueued_job(OfferReminderJob).with(an_instance_of(Offer)).at(24.hours.from_now).exactly(:once)
    end
  end
end
