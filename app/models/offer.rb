class Offer < ApplicationRecord
  belongs_to :offerer, class_name: "User"
  belongs_to :pair_request
  belongs_to :period

  validates :message, presence: true
  validates :pair_request_id, uniqueness: { scope: :offerer_id }

  scope :future, -> { joins(:period).merge(Period.future) }

  after_create :setup_activity
  after_update :setup_activity_two

  private

  def setup_activity
    Activity.create!(
      receiver: offerer,
      title: ["Your offer has been sent, good luck", "You are first one to make an offer to..., good luck"].sample,
      content: "We have sent an offer"
    )

    Activity.create!(
      receiver: pair_request.user,
      title: ["Offer incoming", "New Offer for ya", "We told you, you'l have an offer soon. And guess what"].sample,
      content: "You have received an offer"
    )
  end

  def setup_activity_two
    return unless accepted_at_previously_changed?(from: nil)

    Activity.create!(
      receiver: offerer,
      title: ["Your offer just got accepted", "Way the go, you're offer just got accepted"].sample,
      content: "Happy Pairin! Have fun"
    )

    pair_request.offers.excluding(self).each do |offer|
      Activity.create!(
        receiver: offer.offerer,
        title: ["Ouch", "Better luck next time"].sample,
        content: "Sorry, but this and that"
      )
    end
  end
end
