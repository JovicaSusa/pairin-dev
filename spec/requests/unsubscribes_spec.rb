require "rails_helper"

RSpec.describe "Unsubscribing", type: :request do
  let(:user) { create(:user) }
  let(:token) { user.unsubscribe_token("suggestions") }

  it "doesn't unsubscribe just from opening the link" do
    get unsubscribe_path(category: "suggestions", token:)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Unsubscribe?")
    expect(user.reload).not_to be_opted_out_of("suggestions")
  end

  it "unsubscribes on POST, with no login, and only from that category" do
    post unsubscribe_path(category: "suggestions", token:)

    expect(user.reload).to be_opted_out_of("suggestions")
    expect(user).not_to be_opted_out_of("announcements")

    follow_redirect!
    expect(response.body).to include("You're unsubscribed")
  end

  it "handles announcements too" do
    post unsubscribe_path(category: "announcements", token: user.unsubscribe_token("announcements"))

    expect(user.reload).to be_opted_out_of("announcements")
    expect(user).not_to be_opted_out_of("suggestions")
  end

  it "works the way mail apps do it, without a CSRF token" do
    ActionController::Base.allow_forgery_protection = true

    post unsubscribe_path(category: "suggestions", token:), params: { "List-Unsubscribe" => "One-Click" }

    expect(user.reload).to be_opted_out_of("suggestions")
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  it "doesn't accept one category's token for the other" do
    post unsubscribe_path(category: "announcements", token:)

    expect(response).to have_http_status(:not_found)
    expect(user.reload).not_to be_opted_out_of("announcements")
  end

  it "refuses a tampered token and an unknown category" do
    post unsubscribe_path(category: "suggestions", token: "#{token}x")
    expect(response).to have_http_status(:not_found)

    post unsubscribe_path(category: "encrypted_password", token:)
    expect(response).to have_http_status(:not_found)

    expect(user.reload).not_to be_opted_out_of("suggestions")
  end

  it "keeps the token away from analytics" do
    get unsubscribe_path(category: "suggestions", token:)

    expect(response.body).not_to include("posthog")
    expect(response.headers["X-Robots-Tag"]).to include("noindex")
  end

  it "keeps the first time when done twice" do
    post unsubscribe_path(category: "suggestions", token:)
    first = user.reload.suggestions_opted_out_at

    travel 1.day do
      post unsubscribe_path(category: "suggestions", token:)
    end

    expect(user.reload.suggestions_opted_out_at).to eq(first)
  end

  describe "the optional emails" do
    let(:offer) { create(:offer, offerer: user) }

    def expect_unsubscribable(mail)
      url = "/unsubscribe/suggestions/"

      expect(mail.header["List-Unsubscribe"].value).to match(%r{\A<https?://[^>]+#{url}[^>]+>\z})
      expect(mail.header["List-Unsubscribe-Post"].value).to eq("List-Unsubscribe=One-Click")
      expect(mail.body.encoded).to include(url)
      expect(mail.body.encoded).to include("Unsubscribe from these emails")

      token = mail.header["List-Unsubscribe"].value[%r{/unsubscribe/suggestions/([^>]+)>}, 1]
      expect(User.find_by_unsubscribe_token("suggestions", token)).to eq(user)
    end

    it "the polite 72-hour email carries it" do
      expect_unsubscribable(OfferMailer.with(offer:).offer_expired_email)
    end

    it "the search-filled email carries it" do
      expect_unsubscribable(OfferMailer.with(offer:).search_filled_email)
    end

    it "the weekly check-in carries it" do
      offer.post_message(offer.poster, "Hi")
      offer.propose_partnership!(by: user)
      partnership = offer.accept_proposal!(by: offer.poster)
      check_in = CheckIn.create!(partnership:, user:, week: 1)

      expect_unsubscribable(CheckInMailer.with(check_in:).weekly_email)
    end

    it "emails that are always sent don't" do
      mail = OfferMailer.with(offer:).offer_received_email

      expect(mail.header["List-Unsubscribe"]).to be_nil
      expect(mail.body.encoded).not_to include("Unsubscribe from these emails")
    end
  end

  describe "after opting out" do
    around do |example|
      Rails.configuration.x.send_suggestion_emails = true
      example.run
    ensure
      Rails.configuration.x.send_suggestion_emails = false
    end

    before { user.opt_out_of!("suggestions") }

    it "stops the polite 72-hour email, but not the search going Off" do
      offer = create(:offer, offerer: user)
      travel_to(offer.expires_at)

      expect { OfferExpiryJob.perform_now(offer) }
        .to have_enqueued_mail(PairRequestMailer, :request_paused_email)
        .and not_have_enqueued_mail(OfferMailer, :offer_expired_email)

      expect(offer.reload.expiry_notified_at).to be_nil
    end

    it "stops the search-filled email" do
      search = create(:pair_request)
      create(:offer, pair_request: search, offerer: user)
      winner = create(:offer, pair_request: search)
      winner.post_message(search.user, "Hi")
      winner.propose_partnership!(by: winner.offerer)

      expect { winner.accept_proposal!(by: search.user) }.not_to have_enqueued_mail(OfferMailer, :search_filled_email)
    end

    it "stops their check-ins, but not their partner's" do
      offer = create(:offer, offerer: user)
      offer.post_message(offer.poster, "Hi")
      offer.propose_partnership!(by: user)
      partnership = offer.accept_proposal!(by: offer.poster)
      travel 7.days + 1.minute

      expect { SendWeeklyCheckInsJob.perform_now }.to have_enqueued_mail(CheckInMailer, :weekly_email).once

      expect(partnership.check_ins.pluck(:user_id)).to eq([offer.poster.id])
    end

    it "keeps the emails about their own searches and conversations" do
      offer = create(:offer, pair_request: create(:pair_request, user:))

      expect { OfferReminderJob.perform_now(offer) }.to have_enqueued_mail(OfferMailer, :offer_reminder_email)
    end
  end
end
