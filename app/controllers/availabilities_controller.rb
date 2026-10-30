class AvailabilitiesController < ApplicationController
  include Authenticated

  def show
    render inertia: "Availability", props: {
      timezone: current_user.timezone,
      windows: current_user.availability_windows.chronological.as_json(only: [:id, :weekday, :start_minute, :end_minute]),
      weekdays: AvailabilityWindow::WEEKDAYS.map { |number, name| { value: number, label: name } }
    }
  end

  def update
    if current_user.update(timezone: params[:timezone])
      redirect_to availability_path, notice: "Timezone saved."
    else
      redirect_to availability_path, inertia: { errors: current_user.errors.to_hash(true) }
    end
  end
end
