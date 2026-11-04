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
    elsif @offer.errors.of_kind?(:pair_request_id, :taken)
      redirect_to pair_requests_path, alert: "You've already applied to this partner search."
    else
      redirect_back_or_to new_pair_request_offer_path(@pair_request), inertia: { errors: @offer.errors.to_hash(true) }
    end
  end

  private

  # From the list's drawer they go back to the same filtered list; from the
  # full form page they go to the list.
  def after_applying(notice:)
    if came_from_the_list?
      redirect_back_or_to pair_requests_path, notice:
    else
      redirect_to pair_requests_path, notice:
    end
  end

  def came_from_the_list?
    URI.parse(request.referer.to_s).path == pair_requests_path
  rescue URI::InvalidURIError
    false
  end

  def reject_switched_off_request
    @pair_request = PairRequest.find(params[:pair_request_id])

    # A block gets the same answer, so it doesn't give itself away.
    if @pair_request.paused? || current_user.blocked_with?(@pair_request.user)
      redirect_to pair_requests_path, alert: "This partner search is switched off and isn't taking applications right now."
    end
  end

  def offer_params = params.require(:offer).permit(:message, :goal, :how_often, :how_long)
end
