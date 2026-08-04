class SessionFeedbacksController < ApplicationController
  include Authenticated

  def new
    @session = Session.find(params[:session_id])
    @session_feedback = @session.session_feedbacks.build(participant: current_user)

    authorize @session_feedback

    render inertia: "SessionFeedbacks/New", props: {
      sessionId: @session.id,
      subject: @session.sessionable.subject,
      otherParticipantName: @session.other_participant(current_user)&.name,
      wentWellValues: SessionFeedback::WENT_WELL_VALUES
    }
  end

  def create
    @session = Session.find(session_feedback_params[:session_id])
    @session_feedback = @session.session_feedbacks.build(
      session_feedback_params.except(:session_id).merge(participant: current_user)
    )

    authorize @session_feedback

    if @session_feedback.save
      redirect_to sessions_path, notice: "Thanks for sharing your retro!"
    else
      redirect_to new_session_feedback_path(session_id: @session.id), inertia: { errors: @session_feedback.errors.to_hash(true) }
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to sessions_path, alert: "You've already submitted feedback for this session."
  end

  private

  def session_feedback_params
    params.require(:session_feedback).permit(:session_id, :went_well, :learned, :notes, :code_snippet, :code_snippet_language, :shared_publicly)
  end
end
