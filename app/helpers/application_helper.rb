module ApplicationHelper
  include Pagy::Frontend

  def active_link_class(path)
    current_page?(path) ? "bg-purple active" : ""
  end

  def root
    user_signed_in? ? activities_path : root_path
  end
end
