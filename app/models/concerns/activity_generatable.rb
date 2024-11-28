require "active_support/concern"

module ActivityGeneratable
  extend ActiveSupport::Concern

  included do
    after_commit :generate_activities
  end

  private

  def generate_activities
    ActivitiesGenerationJob.perform_later(self, previous_changes)
  end
end
