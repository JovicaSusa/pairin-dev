class HomeController < ApplicationController
  layout "marketing"

  def index
    if user_signed_in?
      redirect_to pair_requests_path
    end
  end
end
