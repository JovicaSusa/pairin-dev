class PairRequests::OffersController < ApplicationController
  include Authenticated
  include Alba::Inertia::Controller

  before_action :reject_switched_off_request, only: [:new, :create]

  def index
    @pair_request = current_user.pair_requests.find_by(id: params[:pair_request_id])

    authorize @pair_request, policy_class: PairRequests::OfferPolicy

    @offers = @pair_request.offers.includes(:offerer, :period).order("offers.accepted_at, offers.created_at desc")
    
    render inertia: 'PairRequests/Offers/Index', props: {
      offers: ReceivedOfferResource.new(@offers),
      pairRequestId: @pair_request.id
    }
  end

  def new
    @offer = @pair_request.offers.build(offerer: current_user)

    authorize @offer, :create?, policy_class: PairRequests::OfferPolicy

    render inertia: 'PairRequests/Offers/New', props: {
      pairRequestId: @pair_request.id
    }
  end

  def create
    @offer = @pair_request.offers.build(message: offer_params[:message], offerer: current_user)

    authorize @offer, policy_class: PairRequests::OfferPolicy

    if @offer.save
      OfferMailer.with(offer: @offer).offer_received_email.deliver_later
      OfferExpiryJob.set(wait_until: @offer.expires_at).perform_later(@offer)
      OfferReminderJob.set(wait_until: @offer.reminder_at).perform_later(@offer)

      redirect_to pair_requests_path, notice: "Application sent! We've emailed the poster."
    else
      redirect_to new_pair_request_offer_path(@pair_request), inertia: { errors: @offer.errors.to_hash(true) }
    end
  end

  def accept
    offer = Offer.find(params[:id])

    authorize offer, policy_class: PairRequests::OfferPolicy

    Offers::Accept
      .call(offer)
      .either(
        -> (success) { redirect_to pair_request_offers_path(offer.pair_request_id), notice: "Application accepted. Happy pairin!" },
        -> (failure) { redirect_to pair_request_offers_path(offer.pair_request_id), alert: "Could not accept this application." }
      )
  end

  private

  def reject_switched_off_request
    @pair_request = PairRequest.find(params[:pair_request_id])

    if @pair_request.paused?
      redirect_to pair_requests_path, alert: "This partner search is switched off and isn't taking applications right now."
    end
  end

  def offer_params = params.require(:offer).permit(:message)
end
