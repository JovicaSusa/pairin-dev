class Users::PairRequestsController < ApplicationController
  include Authenticated
  include Alba::Inertia::Controller

  def index
    @pair_requests = current_user.pair_requests.includes(:sessions).order(created_at: :desc)

    respond_to do |format|
      format.html { render :index } # forces rails to use index.html.erb
    end
  end

  def new
    @pair_request = current_user.pair_requests.build
    
    render inertia: 'Users/PairRequests/New', props: {
      pair_request: @pair_request,
      tags: TagResource.new(Tag.select(:id, :name))
    }
  end

  def create
    @pair_request = current_user.pair_requests.build(pair_request_params)

    if @pair_request.save
      redirect_to users_pair_requests_path, notice: "Request posted! Good luck"
    else
      puts "DEBUG: #{@pair_request.errors.full_messages}"
      render inertia: 'Users/PairRequests/New', props: {
        pair_request: @pair_request,
        tags: TagResource.new(Tag.select(:id, :name))
      }, status: :unprocessable_entity
    end
  end

  def add_call_link
    @pair_request = current_user.pair_requests.find(params[:id])

    authorize @pair_request, policy_class: Users::PairRequestPolicy

    if @pair_request.update(add_call_link_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Successfuly added!" }
      end
    end
  end

  private

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
