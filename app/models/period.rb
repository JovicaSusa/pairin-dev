class Period < ApplicationRecord
  belongs_to :periodable, polymorphic: true

  validates :start_at, :end_at, presence: true

  before_validation :set_end_at # TODO: Move this somewhere else(to pair request cntrl)
  # TODO: validate that dates are in the future

  private

  def set_end_at
    self.end_at = self.start_at.advance(minutes: self.periodable.duration)
  end
end
