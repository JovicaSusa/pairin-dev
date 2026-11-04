require "dry/operation/extensions/active_record"

module Offers
  class Accept < Dry::Operation
    include Dry::Operation::Extensions::ActiveRecord

    def self.call(...) = new.call(...)

    def call(offer)
      transaction do
        # Serialize concurrent accepts on the same request (double clicks, two email links).
        offer.pair_request.lock!
        step validate(offer)
        step accept_offer(offer)
      end
    end

    private

    def validate(offer)
      offer.pair_request.has_accepted_offer? ? Failure(:no_longer_acceptable) : Success()
    end

    def accept_offer(offer)
      offer.update!(accepted_at: Time.current)

      Success()
    rescue ActiveRecord::RecordInvalid => e
      Failure(offer: offer, error: e)
    end
  end
end
