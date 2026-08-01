require "active_support/concern"

module FutureDateable
  extend ActiveSupport::Concern

  GRACE_PERIOD = 5.seconds

  private

  def dates_in_future
    errors.add(:end_at, "must be in future") if end_at && end_at < GRACE_PERIOD.ago
    errors.add(:start_at, "must be in future") if start_at && start_at < GRACE_PERIOD.ago
  end
end
