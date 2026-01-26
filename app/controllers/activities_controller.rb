class ActivitiesController < ApplicationController
  include Authenticated

  def index
    @activities = Activity.where(receiver: current_user).order(created_at: :desc)

    render inertia: "Activities", props: {
      activities: @activities
    }
  end
end
