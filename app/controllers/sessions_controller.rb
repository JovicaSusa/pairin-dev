class SessionsController < ApplicationController
  include Authenticated

  def index
    @sessions = current_user.sessions
      .includes([sessionable: :user], :participants)
      .future
      .map { |s| session_props(s) }

    render inertia: 'Sessions/Index', props: {
      sessions: @sessions
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

  def session_props(session)

    other = session.other_participant(current_user)
    {
      id: session.id,
      subject: session.sessionable.subject,
      start_at: session.start_at.to_fs(:short),
      end_at: session.end_at.to_fs(:short),
      call_link: session.formatted_call_link,
      is_holder: session.hold_by_user?(current_user),
      holder_name: session.holder.name,
      other_participant: {
        name: other.name,
        image_url: other.image_url,
        profession: other.profession,
        level: other.level&.titlecase
      }
    }
  end
end
