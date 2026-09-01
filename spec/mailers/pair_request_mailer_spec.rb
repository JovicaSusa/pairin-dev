require 'rails_helper'

RSpec.describe PairRequestMailer, type: :mailer do
  describe "#immediate_expired_email" do
    subject(:mail) { described_class.with(pair_request:, user: pair_request.user).immediate_expired_email }

    let(:pair_request) { create(:pair_request, :immediate) }

    it "renders the headers" do
      expect(mail.to).to eq [pair_request.user.email]
      expect(mail.subject).to eq "Nobody has joined your pair request yet"
    end

    it "renders the pair request subject in the body" do
      expect(mail.body.encoded).to match(pair_request.subject)
    end
  end
end
