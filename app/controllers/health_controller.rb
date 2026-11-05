# For uptime monitors. /up only shows that the app has started, and deploys depend
# on it, so a database problem shouldn't change its answer. This one checks the
# databases too.
class HealthController < ActionController::Base
  def show
    [ ActiveRecord::Base, SolidQueue::Record ].each do |model|
      model.connection.select_value("SELECT 1")
    end

    render plain: "OK"
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    render plain: "Unavailable", status: :service_unavailable
  end
end
