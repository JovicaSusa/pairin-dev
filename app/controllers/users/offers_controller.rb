class Users::OffersController < ApplicationController
  include Authenticated

  def index
    @offers = current_user.offers.includes([pair_request: :user], :period).future.order(created_at: :desc)
  end
end
