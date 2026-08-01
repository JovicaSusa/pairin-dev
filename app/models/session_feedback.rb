class SessionFeedback < ApplicationRecord
  WENT_WELL_VALUES = %w(great good okay tough).freeze

  belongs_to :session
  belongs_to :participant, class_name: "User"

  validates :went_well, inclusion: { in: WENT_WELL_VALUES }, allow_nil: true
  validates :participant_id, uniqueness: { scope: :session_id }
end
