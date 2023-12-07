class PairRequestsController < ApplicationController
  def index
    @pair_requests = PairRequest.where.not(user_id: current_user.id).all
  end

  def search
    @pair_requests = PairRequest.joins(:tags).where(tags: { name: params[:query][:tag] })
  end
end
