class Users::PairRequestsController < ApplicationController
  include Authenticated

  def index
    @pair_requests = current_user.pair_requests.order(created_at: :desc)
  end

  def new
    @pair_request = current_user.pair_requests.build
  end

  def update
    @pair_request = current_user.pair_requests.find(params[:id])

    if @pair_request.update(pair_request_update_params)
      respond_to do |format|
        format.turbo_stream
      end
    end
  end

  def create
    @pair_request = current_user.pair_requests.build(pair_request_params)

    if @pair_request.save
      respond_to do |format|
        format.html { redirect_to users_pair_requests_path, notice: "Request posted! Good luck" }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def pair_request_update_params
    params.require(:pair_request).permit(:call_link)
  end

  def pair_request_params
    params
      .require(:pair_request)
      .permit(
        :subject,
        :description,
        :duration,
        periods_attributes: [:start_at, :_destroy],
        taggings_attributes: [:tag_id, :_destroy, tag_attributes: [:name]]
      )
  end
end
