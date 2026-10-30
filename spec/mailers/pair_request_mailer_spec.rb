require "rails_helper"

RSpec.describe PairRequestMailer, type: :mailer do
  describe "#request_paused_email" do
    let(:poster) { create(:user, email: "poster@example.com") }
    let(:pair_request) { create(:pair_request, user: poster, subject: "Learn Rust together") }

    let(:mail) { described_class.with(pair_request:).request_paused_email }

    it "tells the poster their request was paused" do
      expect(mail.to).to eq(["poster@example.com"])
      expect(mail.subject).to include("paused")
      expect(mail.body.encoded).to include("Learn Rust together")
      expect(mail.body.encoded).to include("an offer went unanswered")
    end

    it "links to a no-login page for turning the request back on" do
      token = mail.body.encoded[%r{/requests/resume/([^"\s]+)}, 1]

      expect(PairRequest.find_by_token_for(:resume, token)).to eq(pair_request)
    end
  end
end
