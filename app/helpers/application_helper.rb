module ApplicationHelper
  include Pagy::Frontend

  def active_link_class(path)
    current_page?(path) ? "bg-purple active" : ""
  end

  def root
    user_signed_in? ? activities_path : root_path
  end

  def canonical_url(path = request.path)
    "https://#{ApplicationController::CANONICAL_HOST}#{path}"
  end
end
