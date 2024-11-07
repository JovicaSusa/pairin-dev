class ActivitiesGenerationJob < ApplicationJob
  queue_as :default

  def perform(record, previous_changes)
    ActivitiesSetup::Proxy.call(record, previous_changes)
  end
end
