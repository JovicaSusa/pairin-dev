# The first-run flow: one question per screen, ending in a live partner search.
class OnboardingsController < ApplicationController
  include Authenticated

  before_action :redirect_if_already_searching

  def show
    render inertia: "Onboarding", props: {
      tags: Tag.order(:name).pluck(:name),
      levels: User::LEVELS.reverse,
      commitments: PairRequest::COMMITMENTS.map { |value, label| { value:, label: } },
      weekdays: AvailabilityWindow::WEEKDAYS.map { |value, label| { value:, label: } },
      level: current_user.level,
      timezone: current_user.timezone
    }
  end

  def create
    result = Onboarding::Finish.call(current_user, onboarding_params)

    if result.success?
      redirect_to users_pair_requests_path, notice: "Your partner search is live!"
    else
      redirect_to onboarding_path, inertia: { errors: result.errors }
    end
  end

  def skip
    current_user.update_columns(onboarding_skipped_at: Time.current)

    redirect_to pair_requests_path
  end

  private

  def redirect_if_already_searching
    redirect_to users_pair_requests_path if current_user.pair_requests.exists?
  end

  def onboarding_params
    params.permit(:level, :goal, :commitment, :timezone, topics: [], windows: [:weekday, :start_minute, :end_minute])
  end
end
