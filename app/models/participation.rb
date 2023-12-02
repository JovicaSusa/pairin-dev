class Participation < ApplicationRecord
  belongs_to :participable, polymorphic: true
  belongs_to :participant, class_name: "User"

  ROLE_INITIATOR = "initiator".freeze
  ROLE_PAIR = "pair"

  validates :role, inclusion: { in: [ROLE_INITIATOR, ROLE_PAIR] }
end
