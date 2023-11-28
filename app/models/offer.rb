class Offer < ApplicationRecord
  belongs_to :offerer, class_name: "User"
  belongs_to :pair_request

  validates :message, presence: true
  validates :pair_request_id, uniqueness: { scope: :offerer_id }
end
