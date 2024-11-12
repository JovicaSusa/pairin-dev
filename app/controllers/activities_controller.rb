class ActivitiesController < ApplicationController
  def index
    @activities = Activity.where(receiver: current_user).order(created_at: :desc)
  end
end
