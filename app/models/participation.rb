class Participation < ApplicationRecord
  belongs_to :participable, polymorphic: true
  belongs_to :participant, class_name: "User"

  ROLE_INITIATOR = "initiator".freeze
  ROLE_PAIR = "pair".freeze

  validates :role, inclusion: { in: [ROLE_INITIATOR, ROLE_PAIR] }

  after_create :setup_activity

  private

  def setup_activity
    Activity.create!(
        receiver: participant,
        title: ["New session scheduled"].sample,
        content: "Happy Pairin! Have fun"
      )
  end
end
