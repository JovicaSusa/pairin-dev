class Users::PairRequestsController < ApplicationController
  include Authenticated
  include Alba::Inertia::Controller
  include SearchCards

  before_action :set_and_authorize_own_pair_request, only: [:pause, :resume]

  def index
    @pair_requests = current_user.pair_requests
      .includes(:tags, :partnership, accepted_offer: :offerer)
      .order(created_at: :desc)

    render inertia: 'Users/PairRequests/Index', props: {
      pairRequests: PairRequestResource.new(@pair_requests),
      matches: PairRequests::Matches.call(@pair_requests.first).map { |match| search_card(match) }
    }
  end

  def new
    @pair_request = current_user.pair_requests.build
    
    render inertia: 'Users/PairRequests/New', props: {
      tags: TagResource.new(Tag.select(:id, :name)),
      commitments: PairRequest::COMMITMENTS.map { |value, label| { value:, label: } }
    }
  end

  def create
    @pair_request = current_user.pair_requests.build(pair_request_params)

    if @pair_request.save
      redirect_to users_pair_requests_path, notice: "Partner search posted! Good luck"
    else
      redirect_back_or_to new_users_pair_request_path, inertia: { errors: @pair_request.errors.to_hash(true) }
    end
  end

  def pause
    @pair_request.switch_off!
    redirect_to users_pair_requests_path, notice: "Partner search switched off. It's hidden from others until you switch it back on."
  end

  def resume
    if @pair_request.switch_on!
      redirect_to users_pair_requests_path, notice: "Partner search switched on. Others can see it and apply again."
    else
      redirect_to users_pair_requests_path, alert: "This partner search has found its partner, so it stays off."
    end
  end

  private

  def set_and_authorize_own_pair_request
    @pair_request = current_user.pair_requests.find(params[:id])

    authorize @pair_request, policy_class: Users::PairRequestPolicy
  end

  def pair_request_params
    params
      .permit(
        :subject,
        :description,
        :commitment,
        taggings_attributes: [:_destroy, tag_attributes: [:name]]
      )
  end
end
