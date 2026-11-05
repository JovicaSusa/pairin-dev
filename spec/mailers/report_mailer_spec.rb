require "rails_helper"

RSpec.describe ReportMailer, type: :mailer do
  let(:poster) { create(:user, name: "Maya", email: "maya@example.com") }
  let(:applicant) { create(:user, name: "Sam", email: "sam@example.com") }
  let(:offer) { create(:offer, pair_request: create(:pair_request, user: poster, subject: "Python buddy"), offerer: applicant, message: "Hi Maya!") }

  let(:mail) { described_class.with(offer:, reporter: poster, reason: "Rude <b>messages</b>").chat_report }

  it "goes to the reports address, and to nobody in the chat" do
    expect(mail.to).to eq(["reports@pairin.dev"])
    expect(mail.to + mail.cc.to_a + mail.bcc.to_a).not_to include("sam@example.com", "maya@example.com")
  end

  it "has both accounts, the reason and the messages, with their text escaped" do
    offer.post_message(poster, "Hello <script>alert(1)</script>")
    body = mail.body.encoded

    expect(body).to include("maya@example.com", "sam@example.com", "user #{poster.id}", "user #{applicant.id}")
    expect(body).to include("Rude &lt;b&gt;messages&lt;/b&gt;")
    expect(body).to include("Hi Maya!", "Hello &lt;script&gt;")
    expect(body).not_to include("<script>")
  end

  it "keeps only the most recent messages, oldest first" do
    offer.post_message(poster, "Opening reply")
    (described_class::RECENT_MESSAGES + 1).times { |i| offer.messages.create!(sender: applicant, body: "Message #{i}", created_at: (i + 1).minutes.from_now) }
    body = mail.body.encoded

    expect(body).not_to include("Message 0<")
    expect(body).to include("Message #{described_class::RECENT_MESSAGES}")
    expect(body.index("Message 1<")).to be < body.index("Message #{described_class::RECENT_MESSAGES}<")
  end
end
