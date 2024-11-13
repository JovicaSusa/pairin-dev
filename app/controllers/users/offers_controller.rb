class Users::OffersController < ApplicationController
  include Authenticated

  def index
    @offers = current_user.offers.future.order(created_at: :desc)
  end
end
