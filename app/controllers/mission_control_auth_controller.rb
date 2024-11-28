class MissionControlAuthController < ApplicationController
  http_basic_authenticate_with name: ENV["BASIC_AUTH_JOBS_NAME"], password: ENV["BASIC_AUTH_JOBS_PASSWORD"]
end
