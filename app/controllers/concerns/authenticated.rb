module Authenticated
  extend ActiveSupport::Concern

  included do
    layout "application"

    before_action :authenticate_user!
    before_action :require_date_of_birth
    before_action :require_name
    around_action :set_timezone, if: :current_user
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  # Accounts from before signup asked for it answer once, before anything else.
  def require_date_of_birth
    redirect_to date_of_birth_path if current_user&.date_of_birth.blank?
  end

  # Partners see the name, so an account without one gives it once, then
  # carries on to the page it asked for (#262).
  def require_name
    return if current_user.nil? || current_user.name.present?

    store_location_for(:user, request.fullpath) if request.get? && request.format.html?
    redirect_to name_path
  end

  def set_timezone
    Time.use_zone(current_user.timezone) { yield }
  end

  def user_not_authorized
    flash[:error] = "Not authorized for this action"
    redirect_to root_path
  end
end
