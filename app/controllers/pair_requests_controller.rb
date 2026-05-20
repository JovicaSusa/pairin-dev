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
      overflow: :empty_page,
    )

    render inertia: 'PairRequests/Index', props: {
      filters: params[:q]&.compact_blank || {},
      pairRequests: InertiaRails.scroll(@pagy) {
        @pair_requests.as_json(
          include: {
            user: { only: [:id, :name], methods: [:image_url] },
            tags: { only: [:id, :name] },
            periods: { only: [:id, :start_at, :end_at] },
            offers: { only: [:offerer_id] }
          }
        )
      },
      filterOptions: InertiaRails.once {
        {
          tags: Tag.all.as_json(only: [:id, :name]),
          userLevels: User::LEVELS,
          languages: I18nData.languages.map { |k, v| [v, k] }
        }
      }
    }
  end
end
