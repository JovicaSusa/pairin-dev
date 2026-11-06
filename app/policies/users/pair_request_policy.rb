module Users
  class PairRequestPolicy < ApplicationPolicy
    def pause?
      user == record.user
    end

    alias_method :resume?, :pause?
    alias_method :edit?, :pause?
    alias_method :update?, :pause?
  end
end
