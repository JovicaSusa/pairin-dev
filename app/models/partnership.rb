# Two people who agreed to work together on a partner search.
class Partnership < ApplicationRecord
  belongs_to :offer
  belongs_to :pair_request

  validates :offer_id, :pair_request_id, uniqueness: true
end
