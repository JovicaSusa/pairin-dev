namespace :stats do
  desc "Print the partner funnel since a date: bin/rails stats:funnel SINCE=2026-12-01"
  task funnel: :environment do
    since = begin
      Date.iso8601(ENV.fetch("SINCE")).beginning_of_day
    rescue KeyError, Date::Error
      abort "Usage: bin/rails stats:funnel SINCE=YYYY-MM-DD"
    end

    puts Stats::Funnel.new(since:).report
  end
end
