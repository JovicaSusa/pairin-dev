class ProfilesController < ApplicationController
  include Authenticated

  def show
    @user = current_user
    
    render inertia: 'Profile', props: {
      user: current_user.as_json(methods: [:image_url]),
      languages: I18nData.languages.invert.to_a,
      countries: I18nData.countries.invert.to_a,
      levels: User::LEVELS.map { |l| [l.capitalize, l] }
    }
  end

  def update
    @user = User.find(params[:id])
    
    if @user.update(profile_attributes)
      redirect_to profile_path(@user.id), notice: "Your profile has been updated!"
    else
      render inertia: 'Profile', props: {
        user: @user.as_json(methods: [:image_url]),
        languages: I18nData.languages.invert.to_a,
        countries: I18nData.countries.invert.to_a,
        levels: User::LEVELS.map { |l| [l.capitalize, l] },
        errors: @user.errors
      }
    end
  end

  private

  def profile_attributes
    params.permit(
      :about, :programming_since, :date_of_birth, :country, :language, :level, :image, :name, :profession
    )
  end
end
