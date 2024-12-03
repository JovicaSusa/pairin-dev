class PairRequestsController < ApplicationController
  include Authenticated
  def index
    @q = PairRequest.ransack(params[:q])
    @pagy, @pair_requests = pagy_countless(
      PairRequest
        .includes(:periods, :tags, :user)
        .active
        .where.not(user_id: current_user.id)
        .all
    )

    render "scrollable_list" if params[:page]
  end

  def search
    @q = PairRequest
      .includes(:tags, :periods, :user)
      .left_joins(:tags, :periods, :user)
      .ransack(params[:q].compact_blank)
    @pagy, @pair_requests = pagy_countless(@q.result(distinct: true))

    render "scrollable_list" if params[:page]
  end
end
