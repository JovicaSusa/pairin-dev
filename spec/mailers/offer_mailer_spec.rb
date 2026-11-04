require "rails_helper"

RSpec.describe OfferMailer, type: :mailer do
  describe "#offer_received_email" do
    let(:poster) { create(:user, email: "poster@example.com", timezone: "UTC") }
    let(:offerer) { create(:user, email: "offerer@example.com", name: "Ada") }
    let(:pair_request) { create(:pair_request, user: poster, subject: "Learn Python together") }
    let(:offer) { create(:offer, pair_request:, offerer:, message: "Happy to pair on this!") }

    let(:mail) { described_class.with(offer:).offer_received_email }

    it "shows the answers and level, next to the search's commitment" do
      pair_request.update!(commitment: "open_ended")
      offer.update!(goal: "Finish a course", how_often: "twice_a_week", how_long: "few_weeks")
      offerer.update!(level: "competent")
      body = mail.body.encoded

      expect(body).to include("Finish a course")
      expect(body).to include("Twice a week")
      expect(body).to include("A few weeks")
      expect(body).to include("Open-ended")
      expect(body).to include("Competent")
    end

    it "is sent to the request's poster" do
      expect(mail.to).to eq(["poster@example.com"])
    end

    it "includes the offer details and a link to the thread" do
      body = mail.body.encoded

      expect(body).to include("Ada")
      expect(body).to include("Happy to pair on this!")
      expect(body).to include("Learn Python together")
      expect(body).not_to include("Time:")
      expect(body).to include("/conversations/#{offer.id}")
      expect(body).not_to include("/offers/confirm")
    end

    it "still shows an old application's time" do
      old = create(:offer, pair_request:, offerer: create(:user), period: create(:period, periodable: pair_request, start_at: Time.utc(2030, 1, 15, 18, 0), end_at: Time.utc(2030, 1, 15, 19, 0)))

      expect(described_class.with(offer: old).offer_received_email.body.encoded).to include("15 Jan 18:00")
    end

    it "shows the applicant's GitHub link only when they've added one" do
      expect(mail.body.encoded).not_to include("GitHub:")

      offerer.update!(github_url: "https://github.com/ada")

      expect(described_class.with(offer:).offer_received_email.body.encoded).to include("https://github.com/ada")
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

  describe "#offer_expired_email" do
    let(:poster) { create(:user, name: "Grace", email: "poster@example.com") }
    let(:offerer) { create(:user, email: "offerer@example.com") }
    let(:pair_request) { create(:pair_request, user: poster, subject: "Learn Python together") }
    let(:offer) { create(:offer, pair_request:, offerer:) }

    let(:mail) { described_class.with(offer:).offer_expired_email }

    it "apologises to the offerer whose offer is still ahead" do
      expect(mail.to).to eq(["offerer@example.com"])
      expect(mail.body.encoded).to include("Grace has gone quiet")
      expect(mail.body.encoded).to include("If they come back and reply")
      expect(mail.body.encoded).not_to include("closed")
      expect(mail.body.encoded).to include("Learn Python together")
      expect(mail.body.encoded).not_to include("poster@example.com")
    end

    it "suggests open requests, each linking to its offer form" do
      suggestion = create(:pair_request, subject: "Pair on Django")

      expect(mail.body.encoded).to include("Pair on Django")
      expect(mail.body.encoded).to include("/pair_requests/#{suggestion.id}/offers/new")
    end

    it "links to the open requests list when there's nothing to suggest" do
      expect(mail.body.encoded).to include("/pair_requests\"")
      expect(mail.body.encoded).not_to include("/offers/new")
    end
  end

  describe "#late_reply_email" do
    let(:poster) { create(:user, name: "Maya", email: "poster@example.com") }
    let(:applicant) { create(:user, email: "applicant@example.com") }
    let(:offer) { create(:offer, pair_request: create(:pair_request, user: poster, subject: "Python buddy"), offerer: applicant) }

    let(:mail) { described_class.with(offer:).late_reply_email }

    it "tells the applicant the poster came back, and links to the thread" do
      expect(mail.to).to eq(["applicant@example.com"])
      expect(mail.subject).to eq("Maya came back and replied")
      expect(mail.body.encoded).to include("Python buddy")
      expect(mail.body.encoded).to include("/conversations/#{offer.id}")
      expect(mail.body.encoded).not_to include("poster@example.com")
    end
  end

  describe "#not_a_match_email" do
    let(:poster) { create(:user, name: "Maya", email: "poster@example.com") }
    let(:applicant) { create(:user, name: "Sam", email: "applicant@example.com") }
    let(:offer) { create(:offer, pair_request: create(:pair_request, user: poster, subject: "Python buddy"), offerer: applicant) }

    let(:mail) { described_class.with(offer:).not_a_match_email }

    it "tells the applicant kindly when the poster ended it, without the reason" do
      offer.not_a_match!(by: poster, reason: "Different goals")

      expect(mail.to).to eq(["applicant@example.com"])
      expect(mail.body.encoded).to include("Maya has ended your conversation")
      expect(mail.body.encoded).to include("Python buddy")
      expect(mail.body.encoded).not_to include("Different goals")
      expect(mail.body.encoded).not_to include("poster@example.com")
    end

    it "tells the poster when the applicant ended it" do
      offer.not_a_match!(by: applicant)

      expect(mail.to).to eq(["poster@example.com"])
      expect(mail.body.encoded).to include("Sam has ended your conversation")
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

    it "links to the thread" do
      expect(mail.body.encoded).to include("/conversations/#{offer.id}")
    end
  end
end
