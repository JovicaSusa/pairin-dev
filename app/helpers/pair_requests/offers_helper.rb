module PairRequests::OffersHelper
  def display_overlay?(offer)
    offer.pair_request.has_accepted_offer? && !offer.accepted?
  end
end
