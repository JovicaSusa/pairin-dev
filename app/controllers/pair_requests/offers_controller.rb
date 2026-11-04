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
      pairRequestId: @pair_request.id,
      commitmentLabel: @pair_request.commitment_label
    }
  end

  def new
    @offer = @pair_request.offers.build(offerer: current_user)

    authorize @offer, :create?, policy_class: PairRequests::OfferPolicy

    render inertia: 'PairRequests/Offers/New', props: {
      pairRequest: @pair_request.as_json(
        only: [:id, :subject, :description],
        methods: [:commitment_label],
        include: { user: { only: [:name] } }
      ),
      applicationOptions: Offer.form_options,
      needsLevel: current_user.level.blank?
    }
  end

  def create
    @offer = @pair_request.offers.build(offer_params.merge(offerer: current_user))

    authorize @offer, policy_class: PairRequests::OfferPolicy

    # Asked once, on the form, when their profile has no level. Saved without
    # the profile's other rules: a half-filled profile mustn't block applying.
    current_user.level = params.dig(:offer, :level).presence if current_user.level.blank?

    if Offer.transaction { @offer.save && current_user.save!(validate: false) }
      OfferMailer.with(offer: @offer).offer_received_email.deliver_later
      OfferExpiryJob.set(wait_until: @offer.expires_at).perform_later(@offer)
      OfferReminderJob.set(wait_until: @offer.reminder_at).perform_later(@offer)

      after_applying notice: "Application sent! We've emailed the poster."
    else
      redirect_back_or_to new_pair_request_offer_path(@pair_request), inertia: { errors: @offer.errors.to_hash(true) }
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

  # From the list's drawer they go back to the same filtered list; from the
  # full form page they go to the list.
  def after_applying(notice:)
    if URI(request.referer.to_s).path == pair_requests_path
      redirect_back_or_to pair_requests_path, notice:
    else
      redirect_to pair_requests_path, notice:
    end
  end

  def reject_switched_off_request
    @pair_request = PairRequest.find(params[:pair_request_id])

    if @pair_request.paused?
      redirect_to pair_requests_path, alert: "This partner search is switched off and isn't taking applications right now."
    end
  end

  def offer_params = params.require(:offer).permit(:message, :goal, :how_often, :how_long)
end
