class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization

  def after_sign_in_path_for(resource_or_scope)
    pair_requests_path
  end
end
