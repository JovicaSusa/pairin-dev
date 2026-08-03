module PairRequests
  class ExtendWait
    def self.call(pair_request) = new(pair_request).call

    def initialize(pair_request)
      @pair_request = pair_request
    end

    def call
      return false unless pair_request.mode == "immediate"
      return false if pair_request.has_accepted_offer?

      period = pair_request.periods.first
      period.update!(start_at: Time.current)

      PairRequests::ScheduleImmediateExpiry.call(pair_request)

      true
    end

    private

    attr_reader :pair_request
  end
end
