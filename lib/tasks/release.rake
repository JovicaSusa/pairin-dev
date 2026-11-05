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
end
