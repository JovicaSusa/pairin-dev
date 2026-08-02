class PairRequestsController < ApplicationController
  include Authenticated
  include Alba::Inertia::Controller

  def index
    live_pair_requests = PairRequest
      .includes(:periods, :tags, :user, :offers)
      .live_now
      .where.not(user_id: current_user.id)
      .distinct

    base = PairRequest
      .includes(:periods, :tags, :user, :offers)
      .left_joins(:periods, :tags, :user)
      .scheduled_active
      .where.not(user_id: current_user.id)

    @q = base.ransack(params[:q]&.compact_blank)
    @pagy, @scheduled_pair_requests = pagy(
      @q.result(distinct: true).order('periods.start_at ASC'),
      items: 15,
      overflow: :empty_page,
    )

    render inertia: 'PairRequests/Index', props: {
      filters: params[:q]&.compact_blank || {},
      livePairRequests: PairRequestBrowseResource.new(live_pair_requests),
      scheduledPairRequestsCount: @pagy.count,
      scheduledPairRequests: InertiaRails.scroll(@pagy) {
        PairRequestBrowseResource.new(@scheduled_pair_requests)
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
