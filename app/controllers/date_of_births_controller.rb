# A one-time step for existing accounts with no date of birth.
class DateOfBirthsController < ApplicationController
  include Authenticated

  skip_before_action :require_date_of_birth
  before_action :redirect_if_answered

  def show
    render inertia: "DateOfBirth"
  end

  def update
    # Checked on a throwaway record: signing out saves the user, and an
    # under-16's date must not be stored.
    if User.new(date_of_birth: params[:date_of_birth], timezone: current_user.timezone).under_age?
      current_user.suspend!
      sign_out(current_user)

      return inertia_location account_suspended_path
    end

    current_user.date_of_birth = params[:date_of_birth]
    current_user.validate
    error = current_user.date_of_birth.blank? ? "can't be blank" : current_user.errors[:date_of_birth].first

    if error
      redirect_to date_of_birth_path, inertia: { errors: { date_of_birth: "Date of birth #{error}" } }
    else
      # Only this field: an older, half-filled profile mustn't block them here.
      current_user.save!(validate: false)

      redirect_to current_user.needs_onboarding? ? onboarding_path : pair_requests_path
    end
  end

  private

  def redirect_if_answered
    redirect_to pair_requests_path if current_user.date_of_birth?
  end
end
