class Period < ApplicationRecord
  belongs_to :periodable, polymorphic: true

  validates :start_at, :end_at, presence: true
  validate :dates_in_future

  before_validation :set_end_at # TODO: Move this somewhere else(to pair request cntrl)

  private

  def set_end_at
    self.end_at = self.start_at.advance(minutes: self.periodable.duration)
  end

  def dates_in_future
    errors.add(:end_at, "must be in future") if end_at && end_at.past?
    errors.add(:start_at, "must be in future") if start_at && start_at.past?
  end
end
