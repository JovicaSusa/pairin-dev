# No-login page reached from the "Did it happen?" email. GET only shows the
# question, because email scanners open every link. POST stores the answer, and
# posting again changes it.
class SessionAnswersController < ApplicationController
  include NoLoginTokenPage

  before_action :set_answer

  def show
    @choice = params[:answer] if %w[yes no].include?(params[:answer])
    @partner = @answer.session.partnership.offer.other_person(@answer.user)
    zone = Time.find_zone!(@answer.user.timezone)
    @starts = @answer.session.start_at.in_time_zone(zone)
  end

  def create
    @answer.answer!(params[:answer] == "yes") if %w[yes no].include?(params[:answer])

    redirect_to session_answer_path(token: params[:token])
  end

  private

  def set_answer
    @answer = SessionAnswer.find_by_token_for(:answer, params[:token])

    render :invalid, status: :not_found unless @answer
  end
end
