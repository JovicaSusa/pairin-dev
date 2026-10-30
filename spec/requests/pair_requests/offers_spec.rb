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

    describe "scheduling the poster's reminder" do
      let(:pair_request) { create(:pair_request, with_periods: false) }
      let(:period) { create(:period, periodable: pair_request, start_at: slot_start, end_at: slot_start + 1.hour) }

      around { |example| freeze_time { example.run } }

      context "when the slot is days away" do
        let(:slot_start) { 3.days.from_now }

        it "reminds the poster 24 hours after the offer" do
          expect { post_offer }
            .to have_enqueued_job(OfferReminderJob).with(an_instance_of(Offer)).at(24.hours.from_now).exactly(:once)
        end
      end

      context "when the slot is sooner than 27 hours away" do
        let(:slot_start) { 10.hours.from_now }

        it "reminds the poster 3 hours before the slot" do
          expect { post_offer }
            .to have_enqueued_job(OfferReminderJob).with(an_instance_of(Offer)).at(7.hours.from_now).exactly(:once)
        end
      end

      context "when the slot is less than 3 hours away" do
        let(:slot_start) { 2.hours.from_now }

        it "schedules no reminder" do
          expect { post_offer }.not_to have_enqueued_job(OfferReminderJob)
        end
      end
    end
  end
end
