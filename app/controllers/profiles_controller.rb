class ProfilesController < ApplicationController
  def show
    @user = current_user
  end

  def update
    user = User.find(params[:id])

    user.update!(profile_attributes)

    redirect_to profile_url(user.id), notice: "You're profile has been updated!"
  end

  private

  def profile_attributes
    params.require(:user).permit(
      :about, :programming_since, :date_of_birth, :country, :language, :level
    )
  end
end
