# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # Set after an under-age attempt. It only covers this browser, so it's a
  # deterrent against retrying with another date, not enforcement.
  AGE_RESTRICTION_COOKIE = :age_restricted

  before_action :configure_sign_up_params, only: [:create]
  before_action :show_age_restriction, only: [:new, :create], if: :age_restricted?
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    if params[:bot_trap].present?
      return redirect_to root_path
    end

    # Under the minimum age: no account, nothing stored, and no retrying
    # with a different date for about a day.
    if (date_of_birth = submitted_date_of_birth) && !User.old_enough?(date_of_birth)
      cookies.signed[AGE_RESTRICTION_COOKIE] = { value: true, expires: 24.hours, httponly: true }
      return redirect_to new_user_registration_path
    end

    super
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:timezone, :date_of_birth])
  end

  def age_restricted?
    cookies.signed[AGE_RESTRICTION_COOKIE].present?
  end

  def show_age_restriction
    request.post? ? redirect_to(new_user_registration_path) : render(:age_restricted)
  end

  # A real date that isn't in the future; anything else is left to the
  # model's validation errors.
  def submitted_date_of_birth
    date = Date.iso8601(params.dig(:user, :date_of_birth).to_s)
    date if date <= Date.current
  rescue Date::Error
    nil
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
