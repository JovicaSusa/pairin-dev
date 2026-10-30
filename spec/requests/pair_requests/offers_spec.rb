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

    context "with a period that doesn't belong to this request" do
      let(:period) { create(:pair_request).periods.first }

      it "rejects the offer and schedules nothing" do
        expect { post_offer }
          .to not_change(Offer, :count)
          .and not_have_enqueued_job(OfferExpiryJob)
      end
    end

    context "with a period that has already started" do
      let(:pair_request) { create(:pair_request, with_periods: false) }
      let(:period) do
        create(:period, periodable: pair_request).tap { |p| p.update_columns(start_at: 1.hour.ago, end_at: 1.minute.ago) }
      end

      it "rejects the offer and schedules nothing" do
        expect { post_offer }
          .to not_change(Offer, :count)
          .and not_have_enqueued_job(OfferExpiryJob)
      end
    end

    context "when the request is switched off" do
      before { pair_request.update!(paused_at: 1.hour.ago) }

      it "rejects the offer with a clear message and emails nobody" do
        expect { post_offer }
          .to not_change(Offer, :count)
          .and not_have_enqueued_mail(OfferMailer, :offer_received_email)

        expect(response).to redirect_to(pair_requests_path)
        expect(flash[:alert]).to eq("This request is switched off and isn't taking offers right now.")
      end

      it "doesn't show the offer form either" do
        get new_pair_request_offer_path(pair_request)

        expect(response).to redirect_to(pair_requests_path)
        expect(flash[:alert]).to eq("This request is switched off and isn't taking offers right now.")
      end
    end

    describe "scheduling the offer's expiry" do
      let(:pair_request) { create(:pair_request, with_periods: false) }
      let(:period) { create(:period, periodable: pair_request, start_at: 2.hours.from_now, end_at: 3.hours.from_now) }

      around { |example| freeze_time { example.run } }

      it "checks the offer when its slot starts, even when it's too close for a reminder" do
        expect { post_offer }
          .to have_enqueued_job(OfferExpiryJob).with(an_instance_of(Offer)).at(2.hours.from_now).exactly(:once)
      end
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
