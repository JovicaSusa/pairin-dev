class ActivitiesController < ApplicationController
  include Authenticated

  def index
    @activities = Activity.where(receiver: current_user).order(created_at: :desc)
  end
end
