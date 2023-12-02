class Session < ApplicationRecord
  belongs_to :sessionable, polymorphic: true
  has_many :participations, as: :participable
  has_many :participants, through: :participations

  validates :start_at, :end_at, presence: true
  validate :dates_in_future, :dates_in_order

  private

  def dates_in_future
    errors.add(:end_at, "must be in future") if end_at && end_at < Time.current
    errors.add(:start_at, "must be in future") if start_at && start_at < Time.current
  end

  def dates_in_order
    return if start_at.blank? || end_at.blank?

    errors.add(:end_at, "must be after start date") if end_at < start_at
  end
end
