class PairRequestsController < ApplicationController
  def index
    @q = PairRequest.ransack(params[:q])

    @pagy, @pair_requests = pagy_countless(PairRequest.where.not(user_id: current_user.id).all)

    render "scrollable_list" if params[:page]
  end

  def search
    @q = PairRequest.left_joins(:tags).ransack(params[:q].compact_blank)
    @pagy, @pair_requests = pagy_countless(@q.result(distinct: true))

    render "scrollable_list" if params[:page]
  end
end
