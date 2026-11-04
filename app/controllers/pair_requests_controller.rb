class PairRequestsController < ApplicationController
  include Authenticated

  def index
    base = PairRequest
      .includes(:tags, :offers, :user)
      .switched_on
      .visible_to(current_user)
      .where.not(user_id: current_user.id)

    @q = base.ransack(searchable_filters)

    @pagy, page = pagy(@q.result(distinct: true).order(created_at: :desc, id: :desc), items: 15, overflow: :empty_page)

    render inertia: 'PairRequests/Index', props: {
      filters: params[:q]&.compact_blank || {},
      pairRequests: InertiaRails.scroll(@pagy) {
        page.map { |pair_request|
          pair_request.as_json(
            methods: [:commitment_label],
            include: {
              tags: { only: [:id, :name] },
              offers: { only: [:offerer_id] }
            }
          ).merge("user" => pair_request.user.profile_for_others.merge(id: pair_request.user_id, name: pair_request.user.name))
        }
      },
      applicationOptions: InertiaRails.once { Offer.form_options },
      needsLevel: current_user.level.blank?,
      filterOptions: InertiaRails.once {
        {
          tags: Tag.all.as_json(only: [:id, :name]),
          commitments: PairRequest::COMMITMENTS.map { |value, label| { value:, label: } },
          userLevels: User::LEVELS,
          languages: I18nData.languages.map { |k, v| [v, k] }
        }
      }
    }
  end

  private

  # Under-18s only get filters on the search itself. Any filter or sort on the
  # poster would reveal what an under-18's profile hides, and adults can't reach
  # under-18 searches at all.
  MINOR_FILTERS = %w[tags_name_eq commitment_eq].freeze

  def searchable_filters
    filters = params[:q]&.compact_blank
    current_user.minor? ? filters&.slice(*MINOR_FILTERS) : filters
  end
end
