class PairRequestsController < ApplicationController
  include Authenticated
  def index
    @q = PairRequest.ransack(params[:q])
    @pagy, @pair_requests = pagy_countless(
      PairRequest
        .includes(:periods, :tags, :user, :offers)
        .active.where.not(user_id: current_user.id)
        .all )

    render inertia: "PairRequests/Index", props: {
      pairRequests: @pair_requests.as_json(
        include: {
          user: { only: [:id, :name, :avatar_url] },
          tags: { only: [:id, :name] },
          periods: { only: [:id, :start_at, :end_at] },
          offers: { only: [:offerer_id] }
        }
      ),
      currentUser: {
        id: current_user.id,
        name: current_user.name
      }
    }
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
