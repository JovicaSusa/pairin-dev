module PairRequests
  # The times someone can book on a request: the poster's weekly hours, read in
  # the poster's timezone and cut into back-to-back slots of the request's call
  # length. Only the next 14 days, nothing within 3 hours, and nothing that
  # overlaps a session the poster already has on any of their requests.
  class BookableSlots
    HORIZON = 14.days
    NOTICE = 3.hours

    Slot = Data.define(:start_at, :end_at)

    def self.call(...) = new(...).call

    def initialize(pair_request)
      @pair_request = pair_request
      @poster = pair_request.user
      @now = Time.current
    end

    def call
      return [] unless @pair_request.duration.to_i.positive?

      earliest = @now + NOTICE
      latest = @now + HORIZON
      busy = @poster.sessions.where("sessions.end_at > ?", @now).to_a

      candidate_dates.flat_map { |date| slots_on(date) }
        .select { |slot| slot.start_at >= earliest && slot.start_at < latest }
        .reject { |slot| busy.any? { |session| session.start_at < slot.end_at && session.end_at > slot.start_at } }
        .sort_by(&:start_at)
    end

    private

    def zone
      @zone ||= ActiveSupport::TimeZone[@poster.timezone.to_s] || ActiveSupport::TimeZone["UTC"]
    end

    # One day either side, so no window is missed when the poster's day doesn't line up with UTC.
    def candidate_dates
      (@now.in_time_zone(zone).to_date - 1)..(@now + HORIZON).in_time_zone(zone).to_date
    end

    def slots_on(date)
      @poster.availability_windows.select { |w| w.weekday == date.cwday }.flat_map do |window|
        cut(wall_time(date, window.start_minute), wall_time(date, window.end_minute))
      end
    end

    def cut(from, to)
      length = @pair_request.duration.minutes
      slots = []

      while from + length <= to
        # A slot spanning a DST change would read e.g. 02:30–02:15 on the clock; skip it.
        slots << Slot.new(start_at: from, end_at: from + length) if from.utc_offset == (from + length).utc_offset
        from += length
      end

      slots
    end

    # Wall-clock time in the poster's zone, so 18:00 stays 18:00 across a DST change.
    def wall_time(date, minute)
      date += minute / AvailabilityWindow::MINUTES_IN_DAY
      minute %= AvailabilityWindow::MINUTES_IN_DAY

      zone.local(date.year, date.month, date.day, minute / 60, minute % 60)
    end
  end
end
