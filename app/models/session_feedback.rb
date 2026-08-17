class SessionFeedback < ApplicationRecord
  include ActivityGeneratable

  WENT_WELL_VALUES = %w(great good okay tough).freeze

  belongs_to :session
  belongs_to :participant, class_name: "User"

  validates :went_well, inclusion: { in: WENT_WELL_VALUES }, allow_blank: true
  validates :participant_id, uniqueness: { scope: :session_id }
  validate :session_has_ended

  scope :shared_publicly, -> { where(shared_publicly: true) }

  private

  def session_has_ended
    return if session.blank? || session.end_at.blank?

    errors.add(:session, "hasn't ended yet - you can leave feedback once it's over") if session.end_at > Time.current
  end
end
