class PairRequestResource < ApplicationResource
  attributes :id, :subject, :description, :mode, :wait_minutes, :cancelled_at

  many :tags, resource: TagResource

  many :sessions, resource: SessionResource

  attribute :periods do |pair_request|
    pair_request.periods.map { |period| { id: period.id, start_at: period.start_at, end_at: period.end_at } }
  end

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
