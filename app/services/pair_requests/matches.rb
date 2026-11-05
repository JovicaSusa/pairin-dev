module PairRequests
  # Open searches for someone who's just posted one: those sharing its tags,
  # from their own age group, that they haven't applied to yet.
  class Matches
    LIMIT = 5

    def self.call(...) = new(...).call

    def initialize(search)
      @search = search
      @viewer = search&.user
    end

    def call
      return PairRequest.none if @search.nil?

      PairRequest
        .switched_on
        .visible_to(@viewer)
        .includes(:tags, :offers, :user)
        .where.not(user_id: @viewer.id)
        .where.not(id: @viewer.offers.select(:pair_request_id))
        .where(id: Tagging.where(taggable_type: "PairRequest", tag_id: @search.tag_ids).select(:taggable_id))
        .order(created_at: :desc, id: :desc)
        .limit(LIMIT)
    end
  end
end
