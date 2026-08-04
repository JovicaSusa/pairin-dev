module Users
  class PairRequestPolicy < ApplicationPolicy
    def add_call_link?
      user == record.user
    end

    def extend_wait?
      user == record.user && record.immediate?
    end

    def reschedule?
      user == record.user && record.immediate?
    end

    def destroy?
      user == record.user
    end
  end
end
