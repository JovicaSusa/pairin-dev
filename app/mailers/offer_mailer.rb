class OfferMailer < ApplicationMailer
  before_action :set_offer

  def offer_received_email
    mail(to: @poster.email, subject: "#{@offerer_name} wants to pair with you")
  end

  def offer_reminder_email
    mail(to: @poster.email, subject: "Reminder: #{@offerer_name} is waiting for your answer")
  end

  private

  def set_offer
    @offer = params[:offer]
    @poster = @offer.pair_request.user
    @offerer_name = @offer.offerer_display_name
    @confirmation_url = offer_confirmation_url(token: @offer.generate_token_for(:poster_confirmation))
  end
end
