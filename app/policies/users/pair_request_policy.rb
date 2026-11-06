module Users
  class PairRequestPolicy < ApplicationPolicy
    def pause?
      user == record.user
    end

    alias_method :resume?, :pause?
  end
end
