require "rails_helper"

RSpec.describe OfferReminderJob, type: :job do
  let(:offer) { create(:offer) }

  def perform = described_class.perform_now(offer)

  it "reminds the poster when the offer is still waiting" do
    expect { perform }
      .to have_enqueued_mail(OfferMailer, :offer_reminder_email).with(params: { offer: }, args: [])
  end

  it "stays quiet when the poster already accepted the offer" do
    offer.update!(accepted_at: Time.current)

    expect { perform }.not_to have_enqueued_mail(OfferMailer, :offer_reminder_email)
  end

  it "stays quiet when the poster accepted another offer" do
    create(:offer, :accepted, pair_request: offer.pair_request)

    expect { perform }.not_to have_enqueued_mail(OfferMailer, :offer_reminder_email)
  end

  it "stays quiet when the request was switched off" do
    offer.pair_request.update!(paused_at: 1.hour.ago)

    expect { perform }.not_to have_enqueued_mail(OfferMailer, :offer_reminder_email)
  end

  it "stays quiet when the poster has replied" do
    offer.post_message(offer.poster, "Great to meet you")

    expect { perform }.not_to have_enqueued_mail(OfferMailer, :offer_reminder_email)
  end

  it "stays quiet when the conversation has ended" do
    offer.not_a_match!(by: offer.poster)

    expect { perform }.not_to have_enqueued_mail(OfferMailer, :offer_reminder_email)
  end
end
