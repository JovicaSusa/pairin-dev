class Session < ApplicationRecord
  belongs_to :pair_request
  belongs_to :offer
end
