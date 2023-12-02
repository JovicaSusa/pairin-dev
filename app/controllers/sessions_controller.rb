class SessionsController < ApplicationController
  def index
    binding.pry
    @sessions = current_user.sessions
  end
end
