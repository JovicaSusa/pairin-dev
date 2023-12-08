class PairRequestsController < ApplicationController
  def index
    @pagy, @pair_requests = pagy_countless(PairRequest.where.not(user_id: current_user.id).all)

    render "scrollable_list" if params[:page]
  end

  def search
    @pair_requests = PairRequest.joins(:tags).where(tags: { name: params[:query][:tag] })
  end
end
