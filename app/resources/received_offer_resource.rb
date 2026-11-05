class ReceivedOfferResource < ApplicationResource
  attributes :id, :message, :status, :goal, :how_often_label, :how_long_label

  attribute :offerer do |offer|
    offer.offerer.profile_for_others.slice(:name, :image_url, :github_url, :level)
  end

  attribute :start_at do |offer|
    offer.period&.start_at
  end

  attribute :end_at do |offer|
    offer.period&.end_at
  end

  attribute :should_overlay do |offer|
    offer.pair_request.has_accepted_offer? && !offer.accepted?
  end

end
