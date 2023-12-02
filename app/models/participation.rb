class Participation < ApplicationRecord
  belongs_to :participable, polymorphic: true
  belongs_to :participant, class_name: "User"

  # TODO: Add role, so that we can know who is who !!!
end
