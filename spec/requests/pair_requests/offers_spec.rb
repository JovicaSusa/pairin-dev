require 'rails_helper'

RSpec.describe "PairRequests::Offers", type: :request do
  # Monday 2 Nov 2026, 08:00 UTC. The factory poster is free every hour, in UTC,
  # so with 60-minute calls the first open slot is 11:00 (3 hours' notice).
  around { |example| travel_to(Time.utc(2026, 11, 2, 8, 0)) { example.run } }

  let(:offerer) { create(:user) }
  let(:pair_request) { create(:pair_request, duration: 60) }
  let(:slot_start) { Time.utc(2026, 11, 2, 11, 0) }

  before { sign_in(offerer) }

  describe "GET /pair_requests/:pair_request_id/offers/new" do
    it "offers the request's bookable slots in the offerer's timezone" do
      offerer.update!(timezone: "Asia/Tokyo")

      get new_pair_request_offer_path(pair_request)

      props = JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
      expect(props["timezone"]).to eq("Asia/Tokyo")
      expect(props["slots"].first).to eq("start_at" => "2026-11-02T11:00:00Z", "end_at" => "2026-11-02T12:00:00Z")
      expect(props["slots"].size).to eq(pair_request.bookable_slots.size)
    end
  end

  describe "POST /pair_requests/:pair_request_id/offers" do
    def post_offer(start_at = slot_start)
      post pair_request_offers_path(pair_request), params: { offer: { message: "Let's pair!", start_at: start_at&.iso8601 } }
    end

    it "books the slot as the offer's own period" do
      expect { post_offer }.to change(Offer, :count).by(1)

      period = Offer.last.period
      expect(period.periodable).to eq(Offer.last)
      expect([period.start_at, period.end_at]).to eq([slot_start, slot_start + 1.hour])
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

    shared_examples "a refused booking" do
      it "rejects the offer and schedules nothing" do
        expect { post_offer(start_at) }
          .to not_change(Offer, :count)
          .and not_change(Period, :count)
          .and not_have_enqueued_job(OfferExpiryJob)

        expect(session[:inertia_errors]).to include(:period)
      end
    end

    context "with a time between slots" do
      let(:start_at) { slot_start + 30.minutes }

      it_behaves_like "a refused booking"
    end

    context "with a time inside the 3-hour notice" do
      let(:start_at) { Time.utc(2026, 11, 2, 10, 0) }

      it_behaves_like "a refused booking"
    end

    context "with no time at all" do
      let(:start_at) { nil }

      it_behaves_like "a refused booking"
    end

    context "with a slot the poster is already in a session for" do
      let(:start_at) { slot_start }

      before do
        create(:session, sessionable: create(:pair_request, user: pair_request.user),
          start_at: slot_start + 15.minutes, end_at: slot_start + 45.minutes)
      end

      it_behaves_like "a refused booking"
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
      it "checks the offer when its slot starts, even when it's too close for a reminder" do
        expect { post_offer }
          .to have_enqueued_job(OfferExpiryJob).with(an_instance_of(Offer)).at(slot_start).exactly(:once)
      end
    end

    describe "scheduling the poster's reminder" do
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

      context "when the slot is just 3 hours away" do
        it "schedules no reminder" do
          expect { post_offer }.not_to have_enqueued_job(OfferReminderJob)
        end
      end
    end
  end
end
