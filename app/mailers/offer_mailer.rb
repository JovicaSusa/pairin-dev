class OfferMailer < ApplicationMailer
  def offer_received_email
    @offer = params[:offer]
    @poster = @offer.pair_request.user
    @offerer_name = @offer.offerer_display_name
    @confirmation_url = offer_confirmation_url(token: @offer.generate_token_for(:poster_confirmation))

    mail(to: @poster.email, subject: "#{@offerer_name} wants to pair with you")
  end
end
