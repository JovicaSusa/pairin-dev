module PairRequests
  class JoinPolicy < ApplicationPolicy
    def create?
      record.user != user && record.immediate? && !record.requires_approval?
    end
  end
end
