module PairRequests
  class ExtendWait < Dry::Operation
    def self.call(...) = new.call(...)

    def call(pair_request)
      step validate(pair_request)

      period = pair_request.periods.first
      period.update!(start_at: Time.current)

      step PairRequests::ScheduleImmediateExpiry.call(pair_request)

      Success(pair_request)
    end

    private

    def validate(pair_request)
      if !pair_request.immediate? || pair_request.has_accepted_offer?
        Failure(:not_extendable)
      else
        Success()
      end
    end
  end
end
