require "dry/operation/extensions/active_record"

module PairRequests
  class InstantJoin < Dry::Operation
    include Dry::Operation::Extensions::ActiveRecord

    def self.call(...) = new.call(...)

    def call(pair_request_id, joiner)
      transaction do
        pair_request = step lock_pair_request(pair_request_id)
        step validate(pair_request, joiner)
        offer = step build_offer(pair_request, joiner)
        step Offers::Accept.call(offer)
      end
    end

    private

    def lock_pair_request(pair_request_id)
      Success(PairRequest.lock.find(pair_request_id))
    end

    def validate(pair_request, joiner)
      if pair_request.user == joiner ||
         !pair_request.immediate? ||
         pair_request.requires_approval? ||
         pair_request.cancelled? ||
         pair_request.has_accepted_offer?
        Failure(:not_joinable)
      else
        Success()
      end
    end

    def build_offer(pair_request, joiner)
      offer = pair_request.offers.build(
        offerer: joiner,
        message: "Joined instantly",
        period: pair_request.periods.first
      )

      offer.save ? Success(offer) : Failure(offer: offer, error: offer.errors)
    end
  end
end
