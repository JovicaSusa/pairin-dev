class Period < ApplicationRecord
  belongs_to :periodable, polymorphic: true

  validates :start_at, :end_at, presence: true
  validate :dates_in_future

  before_validation :set_end_at

  scope :future, -> { where(start_at: Time.zone.now..) }

  class << self
    def ransackable_attributes(auth_object=nil)
      ["start_at", "end_at"]
    end
  end

  private

  def set_end_at
    return if start_at.nil?

    self.end_at = start_at.advance(minutes: self.periodable.duration || 0)
  end

  def dates_in_future
    errors.add(:end_at, "must be in future") if end_at && end_at.past?
    errors.add(:start_at, "must be in future") if start_at && start_at.past?
  end
end
