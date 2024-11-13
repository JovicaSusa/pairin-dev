class SessionsController < ApplicationController
  include Authenticated

  def index
    @sessions = current_user.sessions.future
  end
end
