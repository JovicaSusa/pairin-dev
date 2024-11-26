module Users
  class PairRequestPolicy < ApplicationPolicy
    def add_call_link?
      user == record.user
    end
  end
end
