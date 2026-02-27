class SessionsController < ApplicationController
  include Authenticated
  include Alba::Inertia::Controller
  
  def index
    @sessions = current_user.sessions
      .includes([sessionable: :user], :participants)
      .future

    render inertia: 'Sessions/Index', props: {
      sessions: SessionResource.new(@sessions, params: { current_user: current_user })
    }
  end

  def update
    @session = current_user.sessions.find(params[:id])

    authorize @session

    if @session.update(session_params)
      redirect_to sessions_path, notice: "Call link successfully added!"
    else
      redirect_to sessions_path, alert: "Could not update link."
    end
  end

  private

  def session_params
    params.permit(:call_link)
  end
end
