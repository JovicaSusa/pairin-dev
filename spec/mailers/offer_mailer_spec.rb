require "rails_helper"

RSpec.describe OfferMailer, type: :mailer do
  describe "#offer_received_email" do
    let(:poster) { create(:user, email: "poster@example.com", timezone: "UTC") }
    let(:offerer) { create(:user, email: "offerer@example.com", name: "Ada") }
    let(:pair_request) { create(:pair_request, user: poster, subject: "Learn Python together", with_periods: false) }
    let(:period) { create(:period, periodable: pair_request, start_at: Time.utc(2030, 1, 15, 18, 0), end_at: Time.utc(2030, 1, 15, 19, 0)) }
    let(:offer) { create(:offer, pair_request:, period:, offerer:, message: "Happy to pair on this!") }

    let(:mail) { described_class.with(offer:).offer_received_email }

    it "is sent to the request's poster" do
      expect(mail.to).to eq(["poster@example.com"])
    end

    it "includes the offer details and a link to the no-login confirmation page" do
      body = mail.body.encoded

      expect(body).to include("Ada")
      expect(body).to include("Happy to pair on this!")
      expect(body).to include("Learn Python together")
      expect(body).to include("15 Jan 18:00")
      expect(body).to match(%r{https?://[^/"]+/offers/confirm/[^"\s]+})
    end

    it "never reveals the offerer's email address" do
      expect(mail.body.encoded).not_to include("offerer@example.com")
    end

    context "when the offerer has no name" do
      let(:offerer) { create(:user, name: nil) }

      it "calls them a Pairin member" do
        expect(mail.body.encoded).to include("A Pairin member")
      end
    end
  end

  describe "#offer_reminder_email" do
    let(:poster) { create(:user, email: "poster@example.com") }
    let(:pair_request) { create(:pair_request, user: poster, subject: "Learn Python together") }
    let(:offer) { create(:offer, pair_request:, offerer: create(:user, name: "Ada")) }

    let(:mail) { described_class.with(offer:).offer_reminder_email }

    it "reminds the poster about the waiting offer" do
      expect(mail.to).to eq(["poster@example.com"])
      expect(mail.subject).to include("Reminder")
      expect(mail.body.encoded).to include("Ada")
      expect(mail.body.encoded).to include("Learn Python together")
    end

    it "links to the same no-login confirmation page" do
      token = mail.body.encoded[%r{/offers/confirm/([^"\s]+)}, 1]

      expect(Offer.find_by_token_for(:poster_confirmation, token)).to eq(offer)
    end
  end
end
