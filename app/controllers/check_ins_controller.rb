# No-login page reached from the weekly check-in email. GET only shows the
# question, because email scanners open every link. POST stores the answer.
class CheckInsController < ApplicationController
  include NoLoginTokenPage

  before_action :set_check_in

  def show
    @answer = params[:answer] if %w[yes no].include?(params[:answer])
  end

  def create
    @check_in.answer!(params[:answer] == "yes") if %w[yes no].include?(params[:answer])

    redirect_to check_in_path(token: params[:token])
  end

  private

  def set_check_in
    @check_in = CheckIn.find_by_token_for(:answer, params[:token])

    render :invalid, status: :not_found unless @check_in
  end
end
