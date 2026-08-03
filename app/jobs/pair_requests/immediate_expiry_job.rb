module PairRequests
  class ImmediateExpiryJob < ApplicationJob
    queue_as :default

    def perform(pair_request_id)
      pair_request = PairRequest.find_by(id: pair_request_id)
      return unless pair_request
      return unless pair_request.mode == "immediate"
      return if pair_request.has_accepted_offer?

      period = pair_request.periods.first
      return unless period
      return if Time.current < period.start_at + (pair_request.wait_minutes || 0).minutes

      Activity.create!(
        receiver: pair_request.user,
        title: I18n.t("activities.immediate_expired.titles").sample,
        content: I18n.t("activities.immediate_expired.content").sample
      )

      PairRequestMailer.with(pair_request:, user: pair_request.user).immediate_expired_email.deliver_later
    end
  end
end
