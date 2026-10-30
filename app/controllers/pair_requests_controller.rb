class PairRequestsController < ApplicationController
  include Authenticated

  SLOTS_PREVIEW = 3

  def index
    base = PairRequest
      .includes(:tags, :offers, user: :availability_windows)
      .switched_on
      .where.not(user_id: current_user.id)
      .where(user_id: AvailabilityWindow.select(:user_id))

    @q = base.ransack(params[:q]&.compact_blank&.except(:available_from, :available_to))

    # Slots come from each poster's weekly hours, so filtering and ordering by
    # them happens in Ruby: only requests with an open slot (in the chosen
    # date range), soonest first.
    listed = @q.result(distinct: true).filter_map { |pair_request|
      slots = pair_request.bookable_slots.select { |slot| slot_in_range?(slot) }
      [pair_request, slots] if slots.any?
    }.sort_by { |pair_request, slots| [slots.first.start_at, pair_request.id] }

    @pagy, page = pagy_array(listed, items: 15, overflow: :empty_page)

    render inertia: 'PairRequests/Index', props: {
      filters: params[:q]&.compact_blank || {},
      timezone: current_user.timezone,
      pairRequests: InertiaRails.scroll(@pagy) {
        page.map { |pair_request, slots|
          pair_request.as_json(
            include: {
              user: { only: [:id, :name, :profession], methods: [:image_url, :level_titleized] },
              tags: { only: [:id, :name] },
              offers: { only: [:offerer_id] }
            }
          ).merge(
            "slots" => slots.first(SLOTS_PREVIEW).map { |slot| { start_at: slot.start_at.utc.iso8601, end_at: slot.end_at.utc.iso8601 } },
            "more_slots" => [slots.size - SLOTS_PREVIEW, 0].max
          )
        }
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

  private

  # Dates are whole days in the viewer's timezone (set by Authenticated).
  def slot_in_range?(slot)
    from = filter_date(:available_from)&.beginning_of_day
    to = filter_date(:available_to)&.end_of_day

    (from.nil? || slot.start_at >= from) && (to.nil? || slot.start_at <= to)
  end

  def filter_date(key)
    value = params.dig(:q, key).presence
    value && Time.zone.parse(value)
  rescue ArgumentError
    nil
  end
end
