class SessionSummaryResource < ApplicationResource
  attributes :id, :subject, :description, :goal, :platform, :plan

  many :tags, resource: TagResource

  attribute :session_feedbacks do |pair_request|
    session = pair_request.sessions.select { |s| s.end_at <= Time.current }.max_by(&:end_at)
    next [] unless session

    session.session_feedbacks.select(&:shared_publicly?).map do |feedback|
      {
        went_well: feedback.went_well,
        learned: feedback.learned,
        notes: feedback.notes,
        participant: {
          id: feedback.participant_id,
          name: feedback.participant.name
        }
      }
    end
  end
end
