class PairRequestsController < ApplicationController
  include Authenticated
  def index
    base = PairRequest
      .includes(:periods, :tags, :user, :offers)
      .left_joins(:periods, :tags, :user)
      .active
      .where.not(user_id: current_user.id)

    @q = base.ransack(params[:q])
    @pair_requests = @q.result(distinct: true).order('periods.start_at ASC')

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
      },
      filterOptions: {
        tags: Tag.all.as_json(only: [:id, :name]), 
        userLevels: User::LEVELS, 
        languages: I18nData.languages.map { |k,v| [v,k] } 
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
