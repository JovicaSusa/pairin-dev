require "rails_helper"

RSpec.describe UnreadMessagesEmailJob, type: :job do
  let(:poster) { create(:user) }
  let(:applicant) { create(:user) }
  let(:offer) { create(:offer, pair_request: create(:pair_request, user: poster), offerer: applicant) }

  # The applicant has read the thread, and the poster's reply is what's unread.
  before do
    offer.mark_read_by!(applicant)
    travel 1.minute
    offer.post_message(poster, "Great to meet you")
  end

  def perform = described_class.perform_now(offer, applicant)

  def email_sent
    have_enqueued_mail(OfferMailer, :unread_messages_email).with(params: { offer:, recipient: applicant }, args: [])
  end

  it "sends one email once a message has waited 15 minutes" do
    travel 15.minutes

    expect { perform }.to email_sent.once
  end

  it "covers everything unread in that one email" do
    travel 5.minutes
    offer.post_message(poster, "Are you around?")
    travel 10.minutes

    expect { perform }.to email_sent.once

    travel 5.minutes
    expect { perform }.not_to email_sent
  end

  it "does nothing before 15 minutes" do
    travel 14.minutes

    expect { perform }.not_to email_sent
  end

  it "is cancelled by reading the thread" do
    travel 5.minutes
    offer.mark_read_by!(applicant)
    travel 10.minutes

    expect { perform }.not_to email_sent
  end

  it "sends no second email until the earlier messages are read" do
    travel 15.minutes
    perform

    travel 1.minute
    offer.post_message(poster, "Hello again")
    travel 15.minutes

    expect { perform }.not_to email_sent
  end

  it "can send another after they've read and more arrive" do
    travel 15.minutes
    perform

    travel 1.minute
    offer.mark_read_by!(applicant)
    travel 1.minute
    offer.post_message(poster, "Hello again")
    travel 15.minutes

    expect { perform }.to email_sent.once
  end

  it "doesn't email early because an older job fired for a newer message" do
    travel 5.minutes
    offer.mark_read_by!(applicant)
    travel 5.minutes
    offer.post_message(poster, "Newer")
    travel 5.minutes

    expect { perform }.not_to email_sent
  end

  it "sends nothing once the conversation has ended" do
    offer.not_a_match!(by: poster)
    travel 15.minutes

    expect { perform }.not_to email_sent
  end

  it "tracks each person separately" do
    offer.mark_read_by!(poster)
    travel 1.minute
    offer.post_message(applicant, "Thanks!")
    travel 15.minutes
    perform

    travel 1.minute
    expect { described_class.perform_now(offer, poster) }
      .to have_enqueued_mail(OfferMailer, :unread_messages_email).with(params: { offer:, recipient: poster }, args: []).once
  end
end
