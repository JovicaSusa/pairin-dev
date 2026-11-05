module Release
  # Sends the launch email once to each confirmed, active user who hasn't opted out.
  # Each person is marked as they're queued, so running it again only reaches
  # whoever it missed.
  class SendLaunchEmail
    def recipients
      User
        .where.not(confirmed_at: nil)
        .where(suspended_at: nil, announcements_opted_out_at: nil, launch_email_sent_at: nil)
    end

    def sent_count
      User.where.not(launch_email_sent_at: nil).count
    end

    def opted_out_count
      User.where.not(announcements_opted_out_at: nil).count
    end

    def send_all
      recipients.find_each do |user|
        LaunchMailer.with(user:).announcement.deliver_later
        user.update_columns(launch_email_sent_at: Time.current)
      end
    end
  end
end
