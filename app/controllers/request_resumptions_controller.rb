# No-login page the poster reaches from the request-paused email.
# GET only shows the request (email scanners open every link); POST switches it back on.
class RequestResumptionsController < ApplicationController
  include NoLoginTokenPage

  before_action :set_pair_request

  def show
  end

  def create
    @pair_request.switch_on!

    redirect_to request_resumption_path(token: params[:token])
  end

  private

  def set_pair_request
    @pair_request = PairRequest.find_by_token_for(:resume, params[:token])

    render :invalid, status: :not_found unless @pair_request
  end
end
