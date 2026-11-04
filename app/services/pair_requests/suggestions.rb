module PairRequests
  # Open requests to suggest to someone whose offer just expired: requests
  # sharing the dead request's tags first, then the newest.
  class Suggestions
    LIMIT = 3

    def self.call(...) = new(...).call

    def initialize(expired_offer)
      @offerer = expired_offer.offerer
      @dead_request = expired_offer.pair_request
    end

    def call
      candidates = PairRequest
        .switched_on
        .visible_to(@offerer)
        .left_joins(:taggings)
        .where.not(id: @dead_request.id)
        .where.not(user_id: @offerer.id)
        .where.not(id: @offerer.offers.select(:pair_request_id))
        .where.not(id: Offer.accepted.select(:pair_request_id))
        .group(:id)

      tag_ids = @dead_request.tags.ids
      if tag_ids.any?
        shared_tags = PairRequest.sanitize_sql_array(["COUNT(DISTINCT taggings.tag_id) FILTER (WHERE taggings.tag_id IN (?)) DESC", tag_ids])
        candidates = candidates.order(Arel.sql(shared_tags))
      end

      candidates.order(created_at: :desc, id: :desc).limit(LIMIT).to_a
    end
  end
end
