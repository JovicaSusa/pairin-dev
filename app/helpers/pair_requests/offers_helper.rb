module PairRequests::OffersHelper
  def hide_accept_btn?(offer)
    offer.accepted? || offer.pair_request.has_accepted_offer?
  end
end
