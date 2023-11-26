class PairRequest < ApplicationRecord
  belongs_to :user

  validates :description, :subject, presence: true
end
