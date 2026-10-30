class Availabilities::WindowsController < ApplicationController
  include Authenticated

  def create
    window = current_user.availability_windows.build(window_params)

    if window.save
      redirect_to availability_path, notice: "Added."
    else
      redirect_to availability_path, inertia: { errors: window.errors.to_hash(true) }
    end
  rescue ActiveRecord::StatementInvalid => e
    # A concurrent request saved an overlapping window after our validation ran.
    raise unless e.cause.is_a?(PG::ExclusionViolation)

    redirect_to availability_path, inertia: { errors: { start_minute: "overlaps hours you've already added" } }
  end

  def destroy
    current_user.availability_windows.find(params[:id]).destroy!

    redirect_to availability_path, notice: "Removed."
  end

  private

  def window_params = params.permit(:weekday, :start_minute, :end_minute)
end
