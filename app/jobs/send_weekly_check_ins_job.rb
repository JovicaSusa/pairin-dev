class SendWeeklyCheckInsJob < ApplicationJob
  queue_as :default

  def perform
    Partnership.where(ended_at: nil).includes(offer: :offerer, pair_request: :user).find_each do |partnership|
      partnership.send_due_check_ins
    end
  end
end
