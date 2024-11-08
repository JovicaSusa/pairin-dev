module PairRequests::OffersHelper
  def hide_accept_btn?(offer)
    offer.pair_request.has_accepted_offer?
  end

  def display_overlay?(offer)
    offer.pair_request.has_accepted_offer? && !offer.accepted?
  end
end
