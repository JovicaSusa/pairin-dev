class PairRequests::JoinsController < ApplicationController
  include Authenticated

  def create
    pair_request = PairRequest.find(params[:pair_request_id])

    authorize pair_request, policy_class: PairRequests::JoinPolicy

    PairRequests::InstantJoin
      .call(pair_request.id, current_user)
      .either(
        -> (success) { redirect_to sessions_path, notice: "You're in! Happy pairin!" },
        -> (failure) { redirect_to pair_requests_path, alert: "This request is no longer available to join." }
      )
  end
end
