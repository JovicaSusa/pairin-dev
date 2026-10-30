# No-login page the poster reaches from the offer-received email.
# GET only shows the offer (email scanners open every link); POST accepts it.
class OfferConfirmationsController < ApplicationController
  include NoLoginTokenPage

  before_action :set_offer

  def show
  end

  def create
    if @offer.pending?
      Offers::Accept.call(@offer).or { flash[:alert] = "Something went wrong accepting this offer. Please try again." }
    end

    redirect_to offer_confirmation_path(token: params[:token])
  end

  private

  def set_offer
    @offer = Offer.find_by_token_for(:poster_confirmation, params[:token])

    render :invalid, status: :not_found unless @offer
  end
end
