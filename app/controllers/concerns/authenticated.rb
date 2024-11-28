module Authenticated
  extend ActiveSupport::Concern

  included do
    layout "app"

    before_action :authenticate_user!
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def user_not_authorized
    flash[:error] = "Not authorized for this action"
    redirect_to root_path
  end
end
