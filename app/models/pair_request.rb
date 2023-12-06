class PairRequest < ApplicationRecord
  belongs_to :user
  has_many :offers, dependent: nil # TODO: Reconsider
  has_many :periods, as: :periodable, dependent: :destroy
  has_many :sessions, as: :sessionable


  validates :description, :subject, :duration, presence: true
  validates :duration, numericality: { greater_than: 0 }

  accepts_nested_attributes_for :periods, reject_if: :all_blank, allow_destroy: true
end
