class SessionsController < ApplicationController
  include Authenticated

  def index
    @sessions = current_user.sessions.future
  end

  def update
    @session = current_user.sessions.find(params[:id])

    if @session.update(session_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Call link successfuly added!" }
      end
    end
  end

  private

  def session_params = params.require(:session).permit(:call_link)
end
