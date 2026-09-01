require "rails_helper"

RSpec.describe SessionMailer, type: :mailer do
  describe "#retro_nag_email" do
    subject(:mail) { described_class.with(session:, participant:).retro_nag_email }

    let(:session) { create(:session, :past) }
    let(:participant) { session.participants.first }

    it "renders the headers" do
      expect(mail.to).to eq [participant.email]
      expect(mail.subject).to eq "Don't forget to leave feedback for your last session"
    end

    it "renders the session subject in the body" do
      expect(mail.body.encoded).to match(session.sessionable.subject)
    end
  end
end
