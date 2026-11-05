class MissionControlAuthController < ApplicationController
  before_action :authenticate_with_basic

  private

  def authenticate_with_basic
    name = Rails.application.credentials.dig(:mission_control, :name)
    password = Rails.application.credentials.dig(:mission_control, :password)

    # Without this, a missing login would let an empty one through.
    return head(:forbidden) if name.blank? || password.blank?

    http_basic_authenticate_or_request_with(name: name, password: password)
  end
end
