class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization

  CANONICAL_HOST = "pairin.dev"

  layout -> { devise_controller? ? 'devise' : 'application' }

  inertia_share auth: -> { { user: current_user } }
  inertia_share unreadMessages: -> { current_user ? current_user.unread_message_counts.values.sum : 0 }

  before_action :redirect_to_canonical_host

  # Back to the page that asked them to sign in, like a thread linked from an email.
  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || (resource_or_scope.needs_onboarding? ? onboarding_path : pair_requests_path)
  end

  private

  # www.pairin.dev and pairin.dev were both serving live, self-canonicalizing
  # duplicates. Force www onto the bare domain so link equity and indexing
  # signals aren't split between the two.
  def redirect_to_canonical_host
    return unless request.host == "www.#{CANONICAL_HOST}"

    redirect_to "https://#{CANONICAL_HOST}#{request.fullpath}",
      status: :moved_permanently, allow_other_host: true
  end
end
