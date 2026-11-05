# Preview all emails at http://localhost:3000/rails/mailers/offer_mailer
class OfferMailerPreview < ActionMailer::Preview
  def offer_received_email
    OfferMailer.with(offer: Offer.last).offer_received_email
  end

  def unread_messages_email
    offer = Offer.last
    OfferMailer.with(offer:, recipient: offer.poster).unread_messages_email
  end

  def partnership_ended_email
    offer = Partnership.last.offer
    OfferMailer.with(offer:, ended_by: offer.poster).partnership_ended_email
  end

  def search_filled_email
    OfferMailer.with(offer: Offer.last).search_filled_email
  end

  def proposal_email
    OfferMailer.with(offer: Offer.where.not(proposed_at: nil).last).proposal_email
  end

  def proposal_reminder_email
    OfferMailer.with(offer: Offer.where.not(proposed_at: nil).last).proposal_reminder_email
  end

  def proposal_accepted_email
    offer = Partnership.last.offer
    OfferMailer.with(offer:, recipient: offer.offerer).proposal_accepted_email
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
