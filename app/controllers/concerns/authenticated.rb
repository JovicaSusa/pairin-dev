module Authenticated
  extend ActiveSupport::Concern

  included do
    layout "application"

    before_action :authenticate_user!
    before_action :require_date_of_birth
    around_action :set_timezone, if: :current_user
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  # Accounts from before signup asked for it answer once, before anything else.
  def require_date_of_birth
    redirect_to date_of_birth_path if current_user&.date_of_birth.blank?
  end

  def set_timezone
    Time.use_zone(current_user.timezone) { yield }
  end

  def user_not_authorized
    flash[:error] = "Not authorized for this action"
    redirect_to root_path
  end
end
