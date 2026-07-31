class PairRequestResource < ApplicationResource
  attributes :id, :subject, :description

  many :tags, resource: TagResource

  many :sessions, resource: SessionResource

  attribute :accepted_offer do |pair_request|
    offer = pair_request.accepted_offer
    if offer
      {
        offerer_name: offer.offerer.name,
        offerer_image: offer.offerer.image_url,
        offerer_profession: offer.offerer.profession,
        offerer_level: offer.offerer.level&.titleize
      }
    end
  end
end
