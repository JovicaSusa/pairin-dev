# A recurring weekly slot when the user is free to pair, e.g. Tuesday 18:00–20:00.
# Times are minutes after midnight in the user's own timezone; weekday is ISO
# (1 = Monday … 7 = Sunday).
class AvailabilityWindow < ApplicationRecord
  WEEKDAYS = { 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday", 5 => "Friday", 6 => "Saturday", 7 => "Sunday" }.freeze
  MINUTES_IN_DAY = 24 * 60

  belongs_to :user

  validates :weekday, inclusion: { in: WEEKDAYS.keys }
  validates :start_minute, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: MINUTES_IN_DAY }
  validates :end_minute, numericality: { only_integer: true, less_than_or_equal_to: MINUTES_IN_DAY }
  validate :ends_after_it_starts
  validate :doesnt_overlap_another_window

  scope :chronological, -> { order(:weekday, :start_minute) }

  private

  def ends_after_it_starts
    return if start_minute.nil? || end_minute.nil?

    errors.add(:end_minute, "must be after the start time") if end_minute <= start_minute
  end

  # Touching windows (18:00–20:00 and 20:00–21:00) are fine; overlapping ones aren't.
  def doesnt_overlap_another_window
    return if user.nil? || weekday.nil? || start_minute.nil? || end_minute.nil?

    overlapping = user.availability_windows
      .where(weekday:)
      .where("start_minute < ? AND end_minute > ?", end_minute, start_minute)
      .where.not(id:)

    errors.add(:start_minute, "overlaps hours you've already added") if overlapping.exists?
  end
end
