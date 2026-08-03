module PairRequests
  class ScheduleImmediateExpiry
    def self.call(pair_request) = new(pair_request).call

    def initialize(pair_request)
      @pair_request = pair_request
    end

    def call
      return false unless pair_request.mode == "immediate"

      period = pair_request.periods.first
      return false unless period

      PairRequests::ImmediateExpiryJob
        .set(wait_until: period.start_at + (pair_request.wait_minutes || 0).minutes)
        .perform_later(pair_request.id)

      true
    end

    private

    attr_reader :pair_request
  end
end
