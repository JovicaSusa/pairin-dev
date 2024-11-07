class Offer < ApplicationRecord
  belongs_to :offerer, class_name: "User"
  belongs_to :pair_request
  belongs_to :period

  validates :message, presence: true
  validates :pair_request_id, uniqueness: { scope: :offerer_id }

  scope :future, -> { joins(:period).merge(Period.future) }

  after_commit :setup_activity

  private

  def setup_activity
    ActivitiesSetup::Proxy.call(self)
  end
end
