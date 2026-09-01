class Users::PairRequestsController < ApplicationController
  include Authenticated
  include Alba::Inertia::Controller

  def index
    @pair_requests = current_user.pair_requests
      .includes(:tags, :sessions, :periods, accepted_offer: :offerer)
      .order(created_at: :desc)

    render inertia: 'Users/PairRequests/Index', props: {
      pairRequests: PairRequestResource.new(@pair_requests)
    }
  end

  def new
    @pair_request = current_user.pair_requests.build

    render inertia: 'Users/PairRequests/New', props: {
      tags: TagResource.new(Tag.select(:id, :name)),
      waitMinutesOptions: PairRequest::WAIT_MINUTES_OPTIONS,
      platformOptions: PairRequest::PLATFORMS
    }
  end

  def create
    @pair_request = current_user.pair_requests.build(pair_request_params)
    @pair_request.periods = [Period.new(start_at: Time.current)] if @pair_request.immediate?

    if @pair_request.save
      PairRequests::ScheduleImmediateExpiry.call(@pair_request)

      redirect_to users_pair_requests_path, notice: "Request posted! Good luck"
    else
      redirect_back_or_to new_users_pair_request_path, inertia: { errors: @pair_request.errors.to_hash(true) }
    end
  end

  def add_call_link
    @pair_request = current_user.pair_requests.find(params[:id])

    authorize @pair_request, policy_class: Users::PairRequestPolicy

    if @pair_request.update(add_call_link_params)
      redirect_to users_pair_requests_path, notice: "Successfully added!"
    else
      redirect_back fallback_location: users_pair_requests_path, alert: "Something went wrong."
    end
  end

  def extend_wait
    @pair_request = current_user.pair_requests.find(params[:id])

    authorize @pair_request, policy_class: Users::PairRequestPolicy

    PairRequests::ExtendWait
      .call(@pair_request)
      .either(
        -> (success) { redirect_to users_pair_requests_path, notice: "We'll keep waiting a bit longer!" },
        -> (failure) { redirect_to users_pair_requests_path, alert: "Could not extend waiting time." }
      )
  end

  def reschedule
    @pair_request = current_user.pair_requests.find(params[:id])

    authorize @pair_request, policy_class: Users::PairRequestPolicy

    PairRequests::Reschedule
      .call(@pair_request, reschedule_params[:periods_attributes])
      .either(
        -> (success) { redirect_to users_pair_requests_path, notice: "Request rescheduled!" },
        -> (failure) { redirect_back fallback_location: users_pair_requests_path, alert: "Could not reschedule request." }
      )
  end

  def destroy
    @pair_request = current_user.pair_requests.find(params[:id])

    authorize @pair_request, policy_class: Users::PairRequestPolicy

    if @pair_request.has_accepted_offer?
      redirect_back fallback_location: users_pair_requests_path, alert: "This request has already been matched and can't be cancelled."
    else
      @pair_request.update!(cancelled_at: Time.current)
      redirect_to users_pair_requests_path, notice: "Request cancelled."
    end
  end

  private

  def add_call_link_params
    params.require(:pair_request).permit(sessions_attributes: [:call_link, :id])
  end

  def reschedule_params
    params.require(:pair_request).permit(periods_attributes: [:start_at])
  end

  def pair_request_params
    params
      .permit(
        :subject,
        :description,
        :duration,
        :mode,
        :wait_minutes,
        :requires_approval,
        :goal,
        :platform,
        :pairing_tool,
        :plan,
        periods_attributes: [:start_at, :_destroy],
        taggings_attributes: [:_destroy, tag_attributes: [:name]]
      )
  end
end
