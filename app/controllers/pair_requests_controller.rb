class PairRequestsController < ApplicationController
  def index
    @pair_requests = PairRequest.where.not(user_id: current_user.id).all
  end
end
