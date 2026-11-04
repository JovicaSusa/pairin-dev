class PairRequestsController < ApplicationController
  include Authenticated

  def index
    base = PairRequest
      .includes(:tags, :offers, :user)
      .switched_on
      .visible_to(current_user)
      .where.not(user_id: current_user.id)

    @q = base.ransack(params[:q]&.compact_blank)

    @pagy, page = pagy(@q.result(distinct: true).order(created_at: :desc, id: :desc), items: 15, overflow: :empty_page)

    render inertia: 'PairRequests/Index', props: {
      filters: params[:q]&.compact_blank || {},
      pairRequests: InertiaRails.scroll(@pagy) {
        page.map { |pair_request|
          pair_request.as_json(
            methods: [:commitment_label],
            include: {
              user: { only: [:id, :name, :profession], methods: [:image_url, :level_titleized] },
              tags: { only: [:id, :name] },
              offers: { only: [:offerer_id] }
            }
          )
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
end
