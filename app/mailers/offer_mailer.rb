class OfferMailer < ApplicationMailer
  before_action :set_offer

  def offer_received_email
    mail(to: @poster.email, subject: "#{@offerer_name} wants to pair with you")
  end

  def offer_reminder_email
    mail(to: @poster.email, subject: "Reminder: #{@offerer_name} is waiting for your answer")
  end

  def offer_expired_email
    @poster_name = @poster.name.presence || "The poster"
    @suggestions = PairRequests::Suggestions.call(@offer)

    mail(to: @offer.offerer.email, subject: "No answer yet on #{@offer.pair_request.subject}")
  end

  # The applicant was told the poster had gone quiet, so this one's good news.
  def late_reply_email
    mail(to: @offer.offerer.email, subject: "#{@poster.display_name} came back and replied")
  end

  # To whoever didn't end it. The reason they gave stays private.
  def not_a_match_email
    @ended_by = @offer.ended_by
    @recipient = @offer.other_person(@ended_by)

    mail(to: @recipient.email, subject: "#{@ended_by.display_name} has ended your conversation")
  end

  private

  def set_offer
    @offer = params[:offer]
    @poster = @offer.pair_request.user
    @offerer_name = @offer.offerer_display_name
    @conversation_url = conversation_url(@offer)
  end
end
