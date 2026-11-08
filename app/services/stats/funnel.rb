module Stats
  # The partner funnel for people who started on or after a date, for reading
  # against the launch target. Each later stage only counts what's in the stages
  # before it, so the numbers narrow from top to bottom.
  class Funnel
    TARGET_PAIRS = 3
    TARGET_DAYS = 30
    FOLLOW_UP_WEEKS = 3
    FOLLOW_UP_DAYS = 60

    def initialize(since:)
      @since = since
    end

    def searches_posted = searches.count
    def applications = offers.count
    def chats_opened = offers.where.not(replied_at: nil).count

    # A proposal leaves proposed_by behind, even once it's accepted or declined.
    def proposals = offers.where.not(proposed_by_id: nil).count

    def signups_via_share_link = User.where(created_at: @since..).where.not(signup_pair_request_id: nil).count
    def applications_via_share_link = offers.where(via_share_link: true).count

    def partnerships_formed = partnerships.count
    def partnerships_ended = partnerships.where.not(ended_at: nil).count

    # Every session starts as a proposal.
    def sessions_proposed = sessions.count

    # Confirmed at some point. A status is overwritten as it changes, but only a
    # confirmed session can be cancelled by a partner, so that counts too. Ones
    # cancelled by the partnership ending can't be told apart, and are left out.
    def sessions_confirmed = sessions.confirmed.or(sessions.cancelled.where.not(cancelled_by_id: nil)).count

    # Completed: at least one partner said Yes to "Did it happen?" (#232).
    def sessions_completed = sessions.completed.count

    def pairs_with_a_completed_session = partnerships.where(id: sessions.completed.select(:partnership_id)).count

    def pairs_with_a_yes = yes_weeks_by_partnership.count { |_id, weeks| weeks.any? }

    # The launch target: at least one Yes, answered within 30 days of the date.
    def pairs_with_a_yes_in_time
      yes_weeks_by_partnership(within: TARGET_DAYS.days).count { |_id, weeks| weeks.any? }
    end

    # The follow-up: Yes answers in 3 separate weeks, within 60 days of the date.
    def pairs_with_three_yes_weeks_in_time
      yes_weeks_by_partnership(within: FOLLOW_UP_DAYS.days).count { |_id, weeks| weeks.size >= FOLLOW_UP_WEEKS }
    end

    def report
      <<~REPORT
        Partner funnel since #{@since.to_date.iso8601}

        Searches posted:        #{searches_posted}
        Applications:           #{applications}
        Chats opened:           #{chats_opened}
        Proposals:              #{proposals}
        Partnerships formed:    #{partnerships_formed}
        Sessions proposed:      #{sessions_proposed}
        Sessions confirmed:     #{sessions_confirmed}
        Completed sessions:     #{sessions_completed}
        Pairs, 1+ session done: #{pairs_with_a_completed_session}
        Pairs with a Yes:       #{pairs_with_a_yes}
        Pairs, #{FOLLOW_UP_WEEKS}+ Yes weeks:   #{partnerships_with_three_yes_weeks}

        Partnerships ended:     #{partnerships_ended}

        Signups via shared link:       #{signups_via_share_link}
        Applications via shared link:  #{applications_via_share_link}

        Target: #{pairs_with_a_yes_in_time} of #{TARGET_PAIRS} pairs with a Yes within #{TARGET_DAYS} days
        Follow-up: #{pairs_with_three_yes_weeks_in_time} pairs with #{FOLLOW_UP_WEEKS} Yes weeks within #{FOLLOW_UP_DAYS} days
      REPORT
    end

    private

    def partnerships_with_three_yes_weeks
      yes_weeks_by_partnership.count { |_id, weeks| weeks.size >= FOLLOW_UP_WEEKS }
    end

    def searches = PairRequest.where(created_at: @since..)
    def offers = Offer.where(created_at: @since..)
    def partnerships = Partnership.where(created_at: @since..)
    # The sessions of the partnerships counted above, so each session stage
    # narrows from "Partnerships formed" like the rest of the funnel.
    def sessions = Session.where(partnership: partnerships)

    # A week counts once, however many partners said Yes for it.
    def yes_weeks_by_partnership(within: nil)
      answers = CheckIn.where(worked_together: true, partnership: partnerships)
      answers = answers.where(answered_at: ..(@since + within)) if within

      answers.pluck(:partnership_id, :week)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last).uniq }
    end
  end
end
