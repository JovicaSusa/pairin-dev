# A time two partners plan to work together. One partner proposes it, and the
# other answers. Times are stored in UTC and entered and shown in each person's
# own timezone.
class Session < ApplicationRecord
  LENGTHS = [30, 45, 60, 90, 120].freeze
  CALL_LINK_MAX_LENGTH = 2000
  # Each proposal emails the other partner, so one person can't pile them up.
  MAX_WAITING = 5

  belongs_to :partnership
  belongs_to :proposed_by, class_name: "User"
  # Nobody when ending the partnership cancelled it.
  belongs_to :cancelled_by, class_name: "User", optional: true

  enum :status, {
    proposed: "proposed",
    confirmed: "confirmed",
    declined: "declined",
    withdrawn: "withdrawn",
    cancelled: "cancelled"
  }, validate: true

  normalizes :call_link, with: ->(link) { link.strip.presence }

  validates :start_at, :end_at, presence: true
  validates :call_link, length: { maximum: CALL_LINK_MAX_LENGTH }
  validate :starts_in_the_future, :not_too_many_waiting, on: :create
  validate :has_a_known_length
  validate :call_link_is_a_web_link

  scope :upcoming, -> { where(start_at: Time.current..).order(:start_at, :id) }
  scope :past, -> { where(start_at: ...Time.current).order(start_at: :desc, id: :desc) }

  # Builds a proposal from what the form sends: a date and a time in the
  # proposer's timezone, and a length in minutes. Anything that doesn't parse
  # is left blank, so validation says what's missing.
  def self.propose(partnership:, by:, date:, time:, minutes:, call_link: nil)
    start_at = local_time(by.timezone, date.to_s, time.to_s)
    minutes = Integer(minutes, exception: false)

    partnership.sessions.new(
      proposed_by: by,
      start_at:,
      end_at: start_at && minutes && start_at + minutes.minutes,
      call_link:
    )
  end

  # "2030-03-04" and "18:30" (browsers may add seconds) in that timezone, or
  # nil unless both are exact.
  def self.local_time(timezone, date, time)
    day = Date.iso8601(date)
    hour, minute = time.match(/\A(\d{2}):(\d{2})(?::\d{2}(?:\.\d+)?)?\z/)&.captures&.map(&:to_i)
    return unless hour && hour < 24 && minute < 60

    Time.find_zone!(timezone).local(day.year, day.month, day.day, hour, minute)
  rescue Date::Error
    nil
  end
  private_class_method :local_time

  def minutes
    ((end_at - start_at) / 60).round
  end

  # A proposal nobody answered before it started can't be confirmed any more.
  def expired?
    proposed? && start_at.past?
  end

  # Who may answer: the partner who didn't propose it, before it starts.
  def answerable_by?(user)
    proposed? && !start_at.past? && user.id != proposed_by_id && partnership.people.include?(user) && !partnership.ended?
  end

  def withdrawable_by?(user)
    proposed? && !start_at.past? && user.id == proposed_by_id && !partnership.ended?
  end

  def cancellable_by?(user)
    confirmed? && !start_at.past? && partnership.people.include?(user) && !partnership.ended?
  end

  # Each returns false if the session can't be changed that way any more, say
  # because the other partner got there first or it has started. Each re-reads
  # the session under its lock.
  def confirm!(by:)
    change!(:confirmed) { answerable_by?(by) }
  end

  def decline!(by:)
    change!(:declined) { answerable_by?(by) }
  end

  def withdraw!(by:)
    change!(:withdrawn) { withdrawable_by?(by) }
  end

  def cancel!(by:)
    change!(:cancelled, cancelled_by: by) { cancellable_by?(by) }
  end

  private

  def change!(status, **attributes)
    with_lock do
      partnership.reload
      next false unless yield

      update!(status:, **attributes)
      true
    end
  end

  def starts_in_the_future
    errors.add(:start_at, "must be in the future") if start_at&.past?
  end

  def not_too_many_waiting
    waiting = partnership.sessions.proposed.where(proposed_by:, start_at: Time.current..).count
    errors.add(:base, "You already have #{MAX_WAITING} proposals waiting for an answer.") if waiting >= MAX_WAITING
  end

  def has_a_known_length
    return unless start_at && end_at

    errors.add(:end_at, "must be one of the lengths offered") unless LENGTHS.include?(minutes)
  end

  def call_link_is_a_web_link
    return if call_link.blank?

    uri = URI.parse(call_link)
    errors.add(:call_link, "must start with http:// or https://") unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:call_link, "isn't a valid link")
  end
end
