class Session < ApplicationRecord
  include FutureDateable

  belongs_to :sessionable, polymorphic: true
  has_many :participations, as: :participable
  has_many :participants, through: :participations
  has_many :session_feedbacks, dependent: :destroy

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
    (participants - [participant]).first
  end

  def feedback_from(participant)
    session_feedbacks.find { |feedback| feedback.participant_id == participant.id }
  end

  def feedback_complete?
    participants.all? { |participant| feedback_from(participant).present? }
  end

  private

  def dates_in_order
    errors.add(:end_at, "must be after start date") if (end_at && start_at) && end_at < start_at
  end
end
