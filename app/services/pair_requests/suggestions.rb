module PairRequests
  # Open requests to suggest to someone whose offer just expired: requests
  # sharing the dead request's tags first, then the soonest bookable slot.
  class Suggestions
    LIMIT = 3

    def self.call(...) = new(...).call

    def initialize(expired_offer)
      @offerer = expired_offer.offerer
      @dead_request = expired_offer.pair_request
    end

    def call
      tag_ids = @dead_request.tags.ids
      shared_tags = if tag_ids.any?
        PairRequest.sanitize_sql_array(["COUNT(DISTINCT taggings.tag_id) FILTER (WHERE taggings.tag_id IN (?))", tag_ids])
      else
        "0"
      end

      candidates = PairRequest
        .switched_on
        .where(user_id: AvailabilityWindow.select(:user_id))
        .left_joins(:taggings)
        .where.not(id: @dead_request.id)
        .where.not(user_id: @offerer.id)
        .where.not(id: @offerer.offers.select(:pair_request_id))
        .where.not(id: Offer.accepted.select(:pair_request_id))
        .group(:id)
        .select("pair_requests.*, #{shared_tags} AS shared_tags")
        .preload(user: :availability_windows)

      # The next slot comes from the poster's weekly hours, so rank in Ruby.
      candidates
        .filter_map { |request| (slot = request.bookable_slots.first) && [request, slot] }
        .sort_by { |request, slot| [-request.shared_tags, slot.start_at, request.id] }
        .first(LIMIT)
        .map(&:first)
    end
  end
end
