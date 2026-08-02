class PairRequestBrowseResource < ApplicationResource
  attributes :id, :subject, :description, :goal, :platform

  many :tags, resource: TagResource

  attribute :periods do |pair_request|
    pair_request.periods.map { |period| { id: period.id, start_at: period.start_at, end_at: period.end_at } }
  end

  attribute :user do |pair_request|
    user = pair_request.user
    {
      name: user.name,
      profession: user.profession,
      image_url: user.image_url,
      level_titleized: user.level_titleized
    }
  end

  attribute :offers do |pair_request|
    pair_request.offers.map { |offer| { offerer_id: offer.offerer_id } }
  end
end
