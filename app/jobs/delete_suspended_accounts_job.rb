# Runs daily. One account that can't be deleted mustn't stop the others.
class DeleteSuspendedAccountsJob < ApplicationJob
  queue_as :default

  def perform
    User.suspended_past_grace_period.find_each do |user|
      user.destroy!
    rescue ActiveRecord::ActiveRecordError => e
      Rails.error.report(e, handled: true, context: { user_id: user.id })
    end
  end
end
