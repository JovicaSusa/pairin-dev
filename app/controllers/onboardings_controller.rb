# The first-run flow: one question per screen, ending in a live partner search.
class OnboardingsController < ApplicationController
  include Authenticated

  # Onboarding asks for the name itself, as its first question.
  skip_before_action :require_name, only: [:show, :profile]
  before_action :redirect_if_already_searching

  def show
    render inertia: "Onboarding", props: {
      tags: Tag.order(:name).pluck(:name),
      levels: User::LEVELS.reverse,
      commitments: PairRequest::COMMITMENTS.map { |value, label| { value:, label: } },
      weekdays: AvailabilityWindow::WEEKDAYS.map { |value, label| { value:, label: } },
      name: current_user.name,
      level: current_user.level,
      about: current_user.about,
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

  # The "about you" part, saved on its own so skipping the search keeps it.
  def profile
    result = Onboarding::Profile.call(current_user, params.permit(:name, :level, :about))

    if result.success?
      redirect_to onboarding_path
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
    params.permit(:goal, :commitment, :timezone, topics: [], windows: [:weekday, :start_minute, :end_minute])
  end
end
