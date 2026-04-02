class Users::OffersController < ApplicationController
  include Authenticated
  include Alba::Inertia::Controller

  def index
    @offers = current_user.offers
                          .includes(:period, pair_request: [:user, { offers: :offerer }])
                          .future
                          .order(created_at: :desc)

    render inertia: 'Users/Offers/Index', props: {
      offers: OfferResource.new(@offers).serializable_hash
    }
  end
end
