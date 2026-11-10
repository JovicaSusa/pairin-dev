# A one-time step for accounts with no name: partners see it, so it comes
# before anything else (#262). New accounts give it in onboarding instead.
class NamesController < ApplicationController
  include Authenticated

  skip_before_action :require_name
  before_action :redirect_if_answered

  def show
    render inertia: "Name"
  end

  def update
    result = Onboarding::Profile.call(current_user, { name: params[:name].to_s })

    if result.success?
      redirect_to stored_location_for(:user) || (current_user.needs_onboarding? ? onboarding_path : pair_requests_path)
    else
      redirect_to name_path, inertia: { errors: result.errors }
    end
  end

  private

  def redirect_if_answered
    redirect_to pair_requests_path if current_user.name.present?
  end
end
