module Users
  class PairRequestPolicy < ApplicationPolicy
    def add_call_link?
      user == record.user
    end

    def pause?
      user == record.user
    end

    alias_method :resume?, :pause?
    alias_method :edit?, :pause?
    alias_method :update?, :pause?
  end
end
