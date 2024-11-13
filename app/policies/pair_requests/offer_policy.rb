module PairRequests
  class OfferPolicy < ApplicationPolicy
    def index?
      record && record.user == user
    end

    def accept?
      user == record.pair_request.user
    end
  end
end
