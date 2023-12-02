class OffersController < ApplicationController
  def index
    @pair_request = current_user.pair_requests.find(params[:pair_request_id])
    @offers = @pair_request.offers
  end

  def new
    @pair_request = PairRequest.find(params[:pair_request_id])
    @offer = @pair_request.offers.build(offerer: current_user)
  end

  def create
    @pair_request = PairRequest.find(params[:pair_request_id])
    @offer = @pair_request.offers.build(offer_params.merge(offerer: current_user))

    if @offer.save
      respond_to do |format|
        format.html { redirect_to pair_requests_path, notice: "We have sent your offer, good luck!" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def accept
    offer = Offer.find(params[:id])

    if Offers::Accept.call(offer)
      redirect_to pair_request_offers_path, notice: "You just scheduled yourself a new pairing session. Happy pairin!"
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def offer_params = params.require(:offer).permit(:message, :period_id)
end
