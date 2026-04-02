class OfferResource < ApplicationResource
  attributes :id, :message, :status

  attribute :subject do |offer|
    offer.pair_request.subject
  end

  attribute :start_at do |offer|
    offer.period.start_at
  end

  attribute :end_at do |offer|
    offer.period.end_at
  end

  attribute :owner do |offer|
    owner = offer.pair_request.user
    {
      name: owner.name,
      image_url: owner.image_url,
      profession: owner.profession,
      level: owner.level&.titleize
    }
  end
end
