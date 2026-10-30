require "rails_helper"

RSpec.describe OfferExpiryJob, type: :job do
  let(:offer) { create(:offer) }
  let(:pair_request) { offer.pair_request }

  def perform = described_class.perform_now(offer)

  context "when the offer's slot started without an answer" do
    before { travel_to(offer.period.start_at) }

    it "switches the request off and tells the poster" do
      expect { perform }
        .to have_enqueued_mail(PairRequestMailer, :request_paused_email).with(params: { pair_request: }, args: [])

      expect(pair_request.reload).to be_paused
    end

    describe "suggestion emails to offerers" do
      around do |example|
        Rails.configuration.x.send_suggestion_emails = true
        example.run
      ensure
        Rails.configuration.x.send_suggestion_emails = false
      end

      it "apologises to everyone with an offer on the request" do
        later_offer = create(:offer, pair_request:, period: create(:period, periodable: pair_request, start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour))

        expect { perform }
          .to have_enqueued_mail(OfferMailer, :offer_expired_email).with(params: { offer: }, args: []).once
          .and have_enqueued_mail(OfferMailer, :offer_expired_email).with(params: { offer: later_offer }, args: []).once
      end

      it "apologises to nobody when it doesn't switch the request off" do
        pair_request.update!(paused_at: 1.day.ago)

        expect { perform }.not_to have_enqueued_mail(OfferMailer, :offer_expired_email)
      end

      it "doesn't email an offerer twice when the request is paused again after a resume" do
        later_offer = create(:offer, pair_request:, period: create(:period, periodable: pair_request, start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour))
        perform
        pair_request.switch_on!
        travel_to(later_offer.period.start_at)

        expect { described_class.perform_now(later_offer) }
          .to have_enqueued_mail(PairRequestMailer, :request_paused_email)
          .and not_have_enqueued_mail(OfferMailer, :offer_expired_email)
      end
    end

    it "holds suggestion emails back while they're switched off" do
      expect { perform }
        .to have_enqueued_mail(PairRequestMailer, :request_paused_email)
        .and not_have_enqueued_mail(OfferMailer, :offer_expired_email)
    end

    it "leaves the request on when the poster accepted this offer" do
      offer.update!(accepted_at: 1.hour.ago)

      expect { perform }.not_to have_enqueued_mail(PairRequestMailer, :request_paused_email)
      expect(pair_request.reload).not_to be_paused
    end

    it "leaves the request on when the poster accepted another offer" do
      create(:offer, :accepted, pair_request:, period: offer.period)

      expect { perform }.not_to have_enqueued_mail(PairRequestMailer, :request_paused_email)
      expect(pair_request.reload).not_to be_paused
    end

    it "doesn't email the poster again when the request is already off" do
      pair_request.update!(paused_at: 1.day.ago)

      expect { perform }.not_to have_enqueued_mail(PairRequestMailer, :request_paused_email)
    end
  end
end
