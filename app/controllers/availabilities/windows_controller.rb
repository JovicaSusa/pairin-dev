class Availabilities::WindowsController < ApplicationController
  include Authenticated

  def create
    window = current_user.availability_windows.build(window_params)

    if window.save
      redirect_to availability_path, notice: "Added."
    else
      redirect_to availability_path, inertia: { errors: window.errors.to_hash(true) }
    end
  end

  def destroy
    current_user.availability_windows.find(params[:id]).destroy!

    redirect_to availability_path, notice: "Removed."
  end

  private

  def window_params = params.permit(:weekday, :start_minute, :end_minute)
end
