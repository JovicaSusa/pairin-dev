# The page behind a partner search's shareable link: readable with no account.
# The layout keeps it out of search engines and loads no analytics.
class PublicSearchesController < ApplicationController
  include NoLoginTokenPage

  before_action :set_search

  def show
  end

  # Nothing is saved here, so it's safe for a scanner to open.
  def apply
    form = new_pair_request_offer_path(@search, via: "share")
    return redirect_to form if user_signed_in?

    store_location_for(:user, form)
    session[:shared_search_token] = @search.share_token

    redirect_to new_user_registration_path
  end

  private

  def set_search
    @search = PairRequest.find_by(share_token: params[:token])

    render :invalid, status: :not_found unless @search&.shareable? && @search.visible_through_link_to?(current_user)
  end
end
