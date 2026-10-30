class PairRequests::OffersController < ApplicationController
  include Authenticated
  include Alba::Inertia::Controller

  def index
    @pair_request = current_user.pair_requests.find_by(id: params[:pair_request_id])

    authorize @pair_request, policy_class: PairRequests::OfferPolicy

    @offers = @pair_request.offers.joins(:period).includes(:offerer, :period, pair_request: :offers).order("offers.accepted_at, periods.start_at desc")
    
    render inertia: 'PairRequests/Offers/Index', props: {
      offers: ReceivedOfferResource.new(@offers),
      pairRequestId: @pair_request.id
    }
  end

  def new
    @pair_request = PairRequest.find(params[:pair_request_id])
    @offer = @pair_request.offers.build(offerer: current_user)

    authorize @offer, :create?, policy_class: PairRequests::OfferPolicy

    render inertia: 'PairRequests/Offers/New', props: {
      pairRequestId: @pair_request.id,
      periods: @pair_request.periods.future.map { |p|
        { id: p.id, start_at: p.start_at, end_at: p.end_at }
      }
    }
  end

  def create
    @pair_request = PairRequest.find(params[:pair_request_id])
    @offer = @pair_request.offers.build(offer_params.merge(offerer: current_user))

    authorize @offer, policy_class: PairRequests::OfferPolicy

    if @offer.save
      OfferMailer.with(offer: @offer).offer_received_email.deliver_later
      if (remind_at = @offer.reminder_at)
        OfferReminderJob.set(wait_until: remind_at).perform_later(@offer)
      end

      redirect_to pair_requests_path, notice: "Offer sent! We've emailed the poster, and you'll get an email when they accept. If they don't respond before your chosen time, the offer expires."
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
        -> (success) { redirect_to pair_request_offers_path(offer.pair_request_id), notice: "You just scheduled yourself a new pairing session. Happy pairin!" },
        -> (failure) { redirect_to pair_request_offers_path(offer.pair_request_id), alert: "Could not accept offer." }
      )
  end

  private

  def offer_params = params.require(:offer).permit(:message, :period_id)
end
