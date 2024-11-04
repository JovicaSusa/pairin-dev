class PairRequests::OffersController < ApplicationController
  def index
    @offers = Offer.where(pair_request_id: params[:pair_request_id]).future
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

    Offers::Accept
      .call(offer)
      .either(
        -> (success) { redirect_to pair_request_offers_path, notice: "You just scheduled yourself a new pairing session. Happy pairin!" },
        -> (failure) { render :index, status: :unprocessable_entity }
      )
  end

  private

  def offer_params = params.require(:offer).permit(:message, :period_id)
end
