class Offer < ApplicationRecord
  belongs_to :offerer, class_name: "User"
  belongs_to :pair_request

  validates :message, presence: true
  validates :offerer_id, uniqueness: { scope: :pair_request_id }
end
