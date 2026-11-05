namespace :release do
  desc "Close data from before the chat-first release. Reports only, unless APPLY=1: bin/rails release:close_old_data BEFORE=2026-12-01T10:00:00Z"
  task close_old_data: :environment do
    before = begin
      Time.iso8601(ENV.fetch("BEFORE"))
    rescue KeyError, ArgumentError
      abort "Usage: bin/rails release:close_old_data BEFORE=2026-12-01T10:00:00Z [APPLY=1]\nBEFORE is the time of the deploy, in UTC."
    end
    abort "BEFORE is in the future, which would also close anything posted from now on." if before.future?

    task = Release::CloseOldData.new(before:)
    print_report = lambda do |report|
      puts "From before #{before.utc.iso8601}:"
      puts "  Searches still On:              #{report.searches_on}"
      puts "  Applications with no reply:     #{report.applications_waiting}"
      puts "  Open chats (left alone):        #{report.chats_open}"
      puts "  Searches with an old time ahead: #{report.searches_with_time_ahead}"
      puts "  Old booked times (kept):        #{report.periods_kept}"
      puts "  Jobs waiting in the queue:      #{report.jobs_waiting.inspect}"
    end

    print_report.call(task.report)

    if ENV["APPLY"] == "1"
      task.apply!
      puts "\nDone. Afterwards:"
      print_report.call(task.report)
    else
      puts "\nNothing changed. Add APPLY=1 to close these."
    end
  end

  desc "Send the launch email. Reports only, unless APPLY=1. LIMIT=50 sends one batch. TEST_EMAIL=you@example.com sends one copy to that account only."
  task send_launch_email: :environment do
    task = Release::SendLaunchEmail.new

    if (email = ENV["TEST_EMAIL"].presence)
      user = User.find_by(email:) || abort("No user with the email #{email}")
      LaunchMailer.with(user:).announcement.deliver_later
      puts "Queued a test copy to #{email}. Nobody is marked as sent."
      next
    end

    limit = ENV["LIMIT"].presence&.then do |value|
      number = Integer(value, exception: false)
      abort "LIMIT must be a whole number above 0, not #{value}" unless number&.positive?
      number
    end

    puts "Will receive it:      #{task.recipients.count}"
    puts "This batch:           #{[ limit, task.recipients.count ].min}" if limit
    puts "Opted out:            #{task.opted_out_count}"
    puts "Already sent to:      #{task.sent_count}"

    if ENV["APPLY"] == "1"
      task.send_all(limit:)
      puts "\nQueued. Sent to so far: #{task.sent_count}"
      puts "Still to send: #{task.recipients.count}"
    else
      puts "\nNothing sent. Add APPLY=1 to send."
    end
  end
end
