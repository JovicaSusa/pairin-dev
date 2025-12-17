class PairRequestsController < ApplicationController
  include Authenticated
  def index
    base = PairRequest
      .includes(:periods, :tags, :user, :offers)
      .left_joins(:periods, :tags, :user)
      .active
      .where.not(user_id: current_user.id)

    @q = base.ransack(params[:q]&.compact_blank)
    @pagy, @pair_requests = pagy(
      @q.result(distinct: true).order('periods.start_at ASC'), 
      items: 15,
    )

    pair_requests_json = @pair_requests.as_json(
      include: {
        user: { only: [:id, :name, :avatar_url] },
        tags: { only: [:id, :name] },
        periods: { only: [:id, :start_at, :end_at] },
        offers: { only: [:offerer_id] }
      }
    )

    respond_to do |format|
      format.html do
        render inertia: "PairRequests/Index", props: {
          pairRequests: pair_requests_json,
          currentUser: {
            id: current_user.id,
            name: current_user.name
          },
          filterOptions: {
            tags: Tag.all.as_json(only: [:id, :name]), 
            userLevels: User::LEVELS, 
            languages: I18nData.languages.map { |k,v| [v,k] } 
          },
          pagination: {
            next: @pagy.next,
          }
        }
      end
      
      format.json do
        render json: {
          pairRequests: pair_requests_json,
          pagination: {
            next: @pagy.next
          }
        }
      end
    end
  end
end
