class ReceivedOfferResource < ApplicationResource
  attributes :id, :message, :status

  attribute :offerer do |offer|
    {
      name: offer.offerer.name,
      image_url: offer.offerer.image_url
    }
  end

  attribute :start_at do |offer|
    offer.period.start_at
  end

  attribute :end_at do |offer|
    offer.period.end_at
  end

  attribute :should_overlay do |offer|
    offer.pair_request.has_accepted_offer? && !offer.accepted?
  end

  attribute :show_accept_button do |offer|
    !offer.pair_request.has_accepted_offer? && !offer.expired?
  end
end
