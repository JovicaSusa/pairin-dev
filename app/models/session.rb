class Session < ApplicationRecord
  belongs_to :sessionable, polymorphic: true
  has_many :participations, as: :participable
  has_many :participants, through: :participations

  validates :start_at, :end_at, presence: true
  validates :call_link, presence: true, on: :update
  validate :dates_in_future, :dates_in_order

  scope :future, -> { where(start_at: Time.current..) }

  def hold_by_user?(user)
    holder == user
  end

  def holder
    sessionable.user
  end

  def other_participant(participant)
    participants.where.not(id: participant.id).first
  end

  private

  def dates_in_future
    errors.add(:end_at, "must be in future") if end_at && end_at.past?
    errors.add(:start_at, "must be in future") if start_at && start_at.past?
  end

  def dates_in_order
    errors.add(:end_at, "must be after start date") if (end_at && start_at) && end_at < start_at
  end
end
