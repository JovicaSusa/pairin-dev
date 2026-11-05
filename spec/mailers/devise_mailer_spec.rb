require "rails_helper"

RSpec.describe Devise::Mailer, type: :mailer do
  let(:user) { create(:user, email: "learner@example.com") }

  shared_examples "a Pairin account email" do |subject:, link:|
    it "says who it is from" do
      expect(mail.subject).to eq(subject)
      expect(mail[:from].value).to eq("Pairin <info@pairin.dev>")
      expect(mail.to).to eq([ "learner@example.com" ])
    end

    it "has an HTML version in the Pairin design and a plain-text version, both with the link" do
      expect(mail.multipart?).to be(true)

      html = mail.html_part.body.to_s
      expect(html).to include(%(src="http://localhost:3000/assets/logo), "Pairin", "<title>Pairin</title>", link)
      expect(html).not_to include("learner@example.com")

      text = mail.text_part.body.to_s
      expect(text).to include("Pairin", link)
      expect(text).not_to include("<a ")
    end
  end

  describe "#reset_password_instructions" do
    let(:mail) { described_class.reset_password_instructions(user, "reset-token") }

    it_behaves_like "a Pairin account email",
      subject: "Reset your Pairin password",
      link: "/users/password/edit?reset_password_token=reset-token"

    it "says how long the link works and that ignoring it is safe" do
      [ mail.html_part, mail.text_part ].each do |part|
        expect(part.body.to_s).to include("6 hours", "ignore this email")
      end
    end
  end

  describe "#confirmation_instructions" do
    let(:mail) { described_class.confirmation_instructions(user, "confirm-token") }

    it_behaves_like "a Pairin account email",
      subject: "Confirm your email for Pairin",
      link: "/users/confirmation?confirmation_token=confirm-token"
  end
end
