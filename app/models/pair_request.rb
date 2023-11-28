class PairRequest < ApplicationRecord
  belongs_to :user
  has_many :offers, dependent: nil # TODO: Reconsider
  has_many :periods, as: :periodable, dependent: :destroy

  validates :description, :subject, :duration, presence: true

  accepts_nested_attributes_for :periods
end
