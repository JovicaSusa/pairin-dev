class Users::PairRequestsController < ApplicationController
  include Authenticated
  include Alba::Inertia::Controller

  before_action :set_and_authorize_own_pair_request, only: [:pause, :resume]

  def index
    @pair_requests = current_user.pair_requests
      .includes(:tags, :sessions, accepted_offer: :offerer)
      .order(created_at: :desc)

    render inertia: 'Users/PairRequests/Index', props: {
      pairRequests: PairRequestResource.new(@pair_requests)
    }
  end

  def new
    @pair_request = current_user.pair_requests.build
    
    render inertia: 'Users/PairRequests/New', props: {
      tags: TagResource.new(Tag.select(:id, :name))
    }
  end

  def create
    @pair_request = current_user.pair_requests.build(pair_request_params)

    if @pair_request.save
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

  def pause
    @pair_request.switch_off!
    redirect_to users_pair_requests_path, notice: "Request switched off. It's hidden from others until you switch it back on."
  end

  def resume
    @pair_request.switch_on!
    redirect_to users_pair_requests_path, notice: "Request switched on. Others can see it and send offers again."
  end

  private

  def set_and_authorize_own_pair_request
    @pair_request = current_user.pair_requests.find(params[:id])

    authorize @pair_request, policy_class: Users::PairRequestPolicy
  end

  def add_call_link_params
    params.require(:pair_request).permit(sessions_attributes: [:call_link, :id])
  end

  def pair_request_params
    params
      .permit(
        :subject,
        :description,
        :duration,
        periods_attributes: [:start_at, :_destroy],
        taggings_attributes: [:_destroy, tag_attributes: [:name]]
      )
  end
end
