# Preview all emails at http://localhost:3000/rails/mailers/offer_mailer
class OfferMailerPreview < ActionMailer::Preview
  def offer_received_email
    OfferMailer.with(offer: Offer.last).offer_received_email
  end

  def offer_expired_email
    OfferMailer.with(offer: Offer.last).offer_expired_email
  end

  def offer_reminder_email
    OfferMailer.with(offer: Offer.last).offer_reminder_email
  end
end
