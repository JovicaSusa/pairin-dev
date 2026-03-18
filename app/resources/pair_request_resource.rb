class PairRequestResource < ApplicationResource
  attributes :id, :subject, :description

  many :tags, resource: TagResource

  many :sessions, resource: SessionResource

  attribute :accepted_offer do |pair_request|
    offer = pair_request.offers.find(&:accepted?)
    if offer
      {
        offerer_name: offer.offerer.name,
        offerer_image: offer.offerer.image_url,
        offerer_profession: offer.offerer.profession,
        offerer_level: offer.offerer.level&.titleize
      }
    end
  end

  attribute :has_accepted_offer do |pair_request|
    pair_request.offers.any?(&:accepted_at)
  end
end
