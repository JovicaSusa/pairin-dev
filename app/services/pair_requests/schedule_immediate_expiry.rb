module PairRequests
  class ScheduleImmediateExpiry < Dry::Operation
    def self.call(...) = new.call(...)

    def call(pair_request)
      step validate(pair_request)

      period = pair_request.periods.first

      PairRequests::ImmediateExpiryJob
        .set(wait_until: period.start_at + (pair_request.wait_minutes || 0).minutes)
        .perform_later(pair_request.id)

      Success(pair_request)
    end

    private

    def validate(pair_request)
      return Failure(:not_immediate) unless pair_request.immediate?

      pair_request.periods.first ? Success() : Failure(:no_period)
    end
  end
end
