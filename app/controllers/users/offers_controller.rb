class Users::OffersController < ApplicationController
  def index
    @offers = current_user.offers.future.order(created_at: :desc)
  end
end
