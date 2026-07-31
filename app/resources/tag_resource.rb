class TagResource < ApplicationResource
  attributes :id, :name

  attribute :value do |tag|
    tag.id
  end

  attribute :label do |tag|
    tag.name
  end
end
