module PairRequests
  class OfferPolicy < ApplicationPolicy
    def index?
      record && record.user == user
    end

    def accept?
      user == record.pair_request.user
    end

    def create?
      record.pair_request.user != user && !record.pair_request.cancelled?
    end
  end
end
