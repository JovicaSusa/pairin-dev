module ApplicationHelper
  include Pagy::Frontend

  def root
    user_signed_in? ? activities_path : root_path
  end

  def canonical_url(path = request.path)
    "https://#{ApplicationController::CANONICAL_HOST}#{path}"
  end
end
