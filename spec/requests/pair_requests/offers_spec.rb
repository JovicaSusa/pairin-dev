require 'rails_helper'

RSpec.describe "PairRequests::Offers", type: :request do
  describe "POST /pair_requests/:pair_request_id/offers" do
    let(:offerer) { create(:user) }
    let(:pair_request) { create(:pair_request) }
    let(:period) { pair_request.periods.first }

    before { sign_in(offerer) }

    def post_offer
      post pair_request_offers_path(pair_request), params: { offer: { message: "Let's pair!", period_id: period.id } }
    end

    it "emails the request's poster about the offer" do
      expect { post_offer }
        .to have_enqueued_mail(OfferMailer, :offer_received_email)
        .with(params: { offer: an_instance_of(Offer) }, args: [])
        .exactly(:once)
    end

    it "tells the offerer the poster has been emailed and what happens next" do
      post_offer

      expect(flash[:notice]).to include("emailed")
      expect(flash[:notice]).to include("If they don't respond")
    end
  end
end
