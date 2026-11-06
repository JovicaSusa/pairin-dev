class PairRequestResource < ApplicationResource
  attributes :id, :subject, :description, :commitment_label

  # Only while it can be applied to, and never for under-18s.
  attribute :share_path do |pair_request|
    "/s/#{pair_request.share_token}" if pair_request.taking_applications? && pair_request.shareable?
  end

  attribute :paused do |pair_request|
    pair_request.paused?
  end

  many :tags, resource: TagResource

  attribute :accepted_offer do |pair_request|
    offer = pair_request.accepted_offer
    if offer
      profile = offer.offerer.profile_for_others

      {
        offerer_name: profile[:name],
        offerer_image: profile[:image_url],
        offerer_profession: profile[:profession],
        offerer_level: profile[:level]
      }
    end
  end
end
