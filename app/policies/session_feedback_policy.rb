class SessionFeedbackPolicy < ApplicationPolicy
  def create?
    record.session.participants.include?(user)
  end
end
