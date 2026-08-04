module Users
  class PairRequestPolicy < ApplicationPolicy
    def add_call_link?
      user == record.user
    end

    def extend_wait?
      user == record.user && record.immediate?
    end
  end
end
