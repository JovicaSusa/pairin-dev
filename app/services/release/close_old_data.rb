module Release
  # One-time, for the chat-first release. Anything from before the release is
  # closed quietly: searches go Off and unanswered applications end, with no
  # emails and no live signals. Old booked times stay as history.
  #
  # It only touches records that are still open, so it's safe to run twice, and
  # the cutoff means nothing posted after the deploy is affected.
  class CloseOldData
    Report = Data.define(:searches_on, :applications_waiting, :chats_open, :searches_with_time_ahead, :periods_kept, :jobs_waiting)

    def initialize(before:)
      @before = before
    end

    def report
      Report.new(
        searches_on: searches.count,
        applications_waiting: applications.count,
        chats_open: chats.count,
        searches_with_time_ahead: Offer.where(created_at: ...@before).joins(:period).merge(Period.where(start_at: Time.current..)).distinct.count(:pair_request_id),
        periods_kept: Period.count,
        jobs_waiting: jobs_waiting
      )
    end

    def apply!
      now = Time.current

      PairRequest.transaction do
        searches.update_all(paused_at: now, updated_at: now)
        # Marked as told, so nothing later sends them the polite email about this.
        applications.update_all(ended_at: now, expiry_notified_at: now, proposed_at: nil, updated_at: now)
      end
    end

    private

    def searches
      PairRequest.where(paused_at: nil, created_at: ...@before)
    end

    def applications
      Offer.where(ended_at: nil, replied_at: nil, accepted_at: nil, created_at: ...@before)
    end

    # Applications accepted the old way already count as replied to. They're
    # reported, not closed, so a real pair isn't cut off without a decision.
    def chats
      Offer.where(ended_at: nil, created_at: ...@before).where.not(replied_at: nil)
    end

    # Jobs queued by the old system. They do nothing once this has run, but it's
    # worth seeing them before a deploy.
    def jobs_waiting
      return {} unless defined?(SolidQueue::Job) && SolidQueue::Job.table_exists?

      SolidQueue::Job.where(finished_at: nil).group(:class_name).count
    end
  end
end
