class Participation < ApplicationRecord
  belongs_to :participable, polymorphic: true
  belongs_to :participant, class_name: "User"

  ROLE_INITIATOR = "initiator".freeze
  ROLE_PAIR = "pair".freeze

  validates :role, inclusion: { in: [ROLE_INITIATOR, ROLE_PAIR] }

  after_commit :setup_activity

  private

  def setup_activity
    ActivitySetup.call(self)
  end
end
