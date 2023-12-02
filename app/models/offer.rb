class Offer < ApplicationRecord
  belongs_to :offerer, class_name: "User"
  belongs_to :pair_request
  belongs_to :period

  validates :message, presence: true
  validates :pair_request_id, uniqueness: { scope: :offerer_id }

  def selected_period
    pair_request.periods.find_by(id: period_id)
  end
end
