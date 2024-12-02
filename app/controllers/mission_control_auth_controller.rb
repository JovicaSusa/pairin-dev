class MissionControlAuthController < ApplicationController
  http_basic_authenticate_with(
    name: Rails.application.credentials.mission_control&.name,
    password: Rails.application.credentials.mission_control&.password
  )
end
