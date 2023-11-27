class PairRequest < ApplicationRecord
  belongs_to :user
  has_many :offers, dependent: nil # TODO: Reconsider

  validates :description, :subject, presence: true
end
