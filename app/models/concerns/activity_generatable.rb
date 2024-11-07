require "active_support/concern"

module ActivityGeneratable
  extend ActiveSupport::Concern

  included do
    after_commit :generate_activities
  end

  private

  def generate_activities
    ActivitiesSetup::Proxy.call(self)
  end
end
