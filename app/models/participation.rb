class Participation < ApplicationRecord
  include ActivityGeneratable

  belongs_to :participable, polymorphic: true
  belongs_to :participant, class_name: "User"

  ROLE_INITIATOR = "initiator".freeze
  ROLE_PAIR = "pair".freeze

  validates :role, inclusion: { in: [ROLE_INITIATOR, ROLE_PAIR] }
end
