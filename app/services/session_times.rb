# When two partners are both usually free, from their weekly availability
# windows (#261). Each window is wall-clock time in its owner's timezone, so it
# is turned into real UTC times day by day, which follows daylight saving.
#
# Suggestions are the start of each stretch where both are free in the next
# week, around confirmed sessions, at least an hour away and long enough for
# the session. The partner's hours also go further ahead, so the form can say
# when a proposal falls outside them. All times go out in UTC, so the page
# shows them in the viewer's timezone and never reveals the partner's.
class SessionTimes
  AHEAD = 7.days
  # How far ahead the form can tell whether a time is in the partner's hours.
  HOURS_AHEAD = 28.days
  NOTICE = 1.hour
  MAX_SUGGESTIONS = 6

  def initialize(partnership, viewer:, now: Time.current)
    @partnership = partnership
    @viewer = viewer
    @partner = partnership.offer.other_person(viewer)
    @now = now
  end

  def suggestions(minutes)
    free = intersect(hours(@viewer, AHEAD), hours(@partner, AHEAD))
    subtract(free, busy)
      .select { |from, to| from >= @now + NOTICE && to - from >= minutes.minutes }
      .map(&:first)
      .first(MAX_SUGGESTIONS)
  end

  def to_props
    {
      suggestions: Session::LENGTHS.index_with { |minutes| suggestions(minutes).map { iso(_1) } },
      my_hours: hours(@viewer, AHEAD).map { |range| range.map { iso(_1) } },
      partner_hours: hours(@partner, HOURS_AHEAD).map { |range| range.map { iso(_1) } }
    }
  end

  private

  # The user's windows from now until `ahead`, as sorted [from, to] UTC pairs,
  # with touching ones (Mon 22:00–24:00 and Tue 00:00–01:00) joined.
  def hours(user, ahead)
    @hours ||= {}
    @hours[[user.id, ahead]] ||= begin
      zone = ActiveSupport::TimeZone[user.timezone] || ActiveSupport::TimeZone["UTC"]
      windows = user.availability_windows.to_a
      finish = @now + ahead
      days = (@now.in_time_zone(zone).to_date - 1)..finish.in_time_zone(zone).to_date

      ranges = days.flat_map do |date|
        windows.select { _1.weekday == date.cwday }.map do |window|
          [wall(zone, date, window.start_minute), wall(zone, date, window.end_minute)]
        end
      end

      # Anything starting within `ahead` counts, at its full length.
      merge(ranges.filter_map { |from, to| [[from, @now].max, to] if to > @now && from < finish && to > from })
    end
  end

  # A minute of a day in a timezone as a UTC time; 1440 is the next midnight.
  def wall(zone, date, minute)
    date += minute / 1440
    minute %= 1440
    zone.local(date.year, date.month, date.day, minute / 60, minute % 60).utc
  end

  def merge(ranges)
    ranges.sort.each_with_object([]) do |(from, to), merged|
      if merged.any? && from <= merged.last[1]
        merged.last[1] = [merged.last[1], to].max
      else
        merged << [from, to]
      end
    end
  end

  def intersect(mine, theirs)
    mine.flat_map do |from, to|
      theirs.filter_map do |other_from, other_to|
        start = [from, other_from].max
        finish = [to, other_to].min
        [start, finish] if finish > start
      end
    end
  end

  # What's left of each stretch once the confirmed sessions are taken out.
  def subtract(ranges, taken)
    taken.reduce(ranges) do |left, (busy_from, busy_to)|
      left.flat_map do |from, to|
        next [[from, to]] if busy_to <= from || busy_from >= to

        [([from, busy_from] if busy_from > from), ([busy_to, to] if busy_to < to)].compact
      end
    end
  end

  def busy
    @partnership.sessions.confirmed.where(end_at: @now..).pluck(:start_at, :end_at).map { |from, to| [from.utc, to.utc] }
  end

  def iso(time) = time.utc.iso8601
end
