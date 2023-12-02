class SessionsController < ApplicationController
  def index
    @sessions = current_user.sessions.future
  end
end
