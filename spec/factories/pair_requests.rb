FactoryBot.define do
  factory(:pair_request) do
    transient do
      # Requests are booked into the poster's weekly hours, so give a poster
      # who has none every hour of the week unless the spec opts out.
      weekly_hours { true }
    end

    user

    subject { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.sentence(word_count: 33) }
    duration { Faker::Number.between(from: 1, to: 90) }

    after(:create) do |pair_request, evaluator|
      poster = pair_request.user

      if evaluator.weekly_hours && poster.availability_windows.none?
        AvailabilityWindow::WEEKDAYS.each_key do |weekday|
          create(:availability_window, user: poster, weekday:, start_minute: 0, end_minute: AvailabilityWindow::MINUTES_IN_DAY)
        end
      end
    end
  end
end
