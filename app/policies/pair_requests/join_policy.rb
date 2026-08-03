module PairRequests
  class JoinPolicy < ApplicationPolicy
    def create?
      record.user != user && record.mode == "immediate" && !record.requires_approval?
    end
  end
end
