class Session < ApplicationRecord
  belongs_to :sessionable, polymorphic: true
  has_many :participations, as: :participable
  has_many :participants, through: :participations

  validates :start_at, :end_at, presence: true
  # TODO: validate that end_at is after start_at
  # TODO: validate that start_at and end_at are in future
end
