class MissionControlAuthController < ApplicationController
  before_action :authenticate_with_basic

  private

  def authenticate_with_basic
    http_basic_authenticate_with(
      name: Rails.application.credentials.dig(:mission_control, :name),
      password: Rails.application.credentials.dig(:mission_control, :password)
    )
  end
end
