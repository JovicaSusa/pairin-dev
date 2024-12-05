module Authenticated
  extend ActiveSupport::Concern

  included do
    layout "app"

    before_action :authenticate_user!
    around_action :set_timezone, if: :current_user
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def set_timezone
    Time.use_zone(current_user.timezone) { yield }
  end

  def user_not_authorized
    flash[:error] = "Not authorized for this action"
    redirect_to root_path
  end
end
