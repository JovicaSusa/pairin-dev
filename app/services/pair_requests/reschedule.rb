module PairRequests
  class Reschedule < Dry::Operation
    def self.call(...) = new.call(...)

    def call(pair_request, periods_attributes)
      step validate(pair_request)

      pair_request.periods.destroy_all

      if pair_request.update(mode: "scheduled", periods_attributes:)
        Success(pair_request)
      else
        Failure(pair_request: pair_request, errors: pair_request.errors)
      end
    end

    private

    def validate(pair_request)
      if !pair_request.immediate? || pair_request.cancelled? || pair_request.has_accepted_offer?
        Failure(:not_reschedulable)
      else
        Success()
      end
    end
  end
end
