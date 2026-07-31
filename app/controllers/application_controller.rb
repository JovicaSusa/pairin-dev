class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization

  layout -> { devise_controller? ? 'devise' : 'application' }

  inertia_share auth: -> { { user: current_user } }

  def after_sign_in_path_for(resource_or_scope)
    pair_requests_path
  end
end
