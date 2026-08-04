class SessionSummariesController < ApplicationController
  include Authenticated
  include Alba::Inertia::Controller

  def index
    base = PairRequest
      .eager_load(sessions: { session_feedbacks: :participant })
      .with_completed_session

    @q = base.ransack(params[:q]&.compact_blank)
    @pagy, @pair_requests = pagy(
      @q.result(distinct: true).order("sessions.end_at DESC"),
      items: 15,
      overflow: :empty_page,
    )

    render inertia: "SessionSummaries/Index", props: {
      sessionSummariesCount: @pagy.count,
      sessionSummaries: InertiaRails.scroll(@pagy) {
        SessionSummaryResource.new(@pair_requests)
      }
    }
  end
end
