# Preview all emails at http://localhost:3000/rails/mailers/offer_mailer
class OfferMailerPreview < ActionMailer::Preview
  def offer_received_email
    OfferMailer.with(offer: Offer.last).offer_received_email
  end

  def unread_messages_email
    offer = Offer.last
    OfferMailer.with(offer:, recipient: offer.poster).unread_messages_email
  end

  def late_reply_email
    OfferMailer.with(offer: Offer.last).late_reply_email
  end

  def not_a_match_email
    OfferMailer.with(offer: Offer.where.not(ended_at: nil).last).not_a_match_email
  end

  def offer_expired_email
    OfferMailer.with(offer: Offer.last).offer_expired_email
  end

  def offer_reminder_email
    OfferMailer.with(offer: Offer.last).offer_reminder_email
  end
end
