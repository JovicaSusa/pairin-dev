# No-login page reached from "Pause this search" in the emails about a search.
# GET only shows it, because email scanners open every link. POST switches it Off.
class RequestPausesController < ApplicationController
  include NoLoginTokenPage

  before_action :set_pair_request

  def show
  end

  def create
    @pair_request.switch_off! unless @pair_request.paused?

    redirect_to request_pause_path(token: params[:token])
  end

  private

  def set_pair_request
    @pair_request = PairRequest.find_by_token_for(:pause, params[:token])

    render :invalid, status: :not_found unless @pair_request
  end
end
