module ActivityGeneratable
  included do
    after_commit :generate_activities
  end

  private

  def generate_activities
    ActivitiesSetup::Proxy.call(self)
  end
end
