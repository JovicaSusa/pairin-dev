# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  timezones = ["Europe/Berlin", "Europe/London", "America/New_York", "Asia/Tokyo", "UTC"]

  posters = Array.new(20) { Faker::Internet.email }.map do |email|
    user = User.create!(email: email, confirmed_at: Time.zone.now, password: "Password33*", timezone: timezones.sample)

    # Weekly hours: three evenings a week, long enough for the longest seeded call.
    [1, 2, 3, 4, 5, 6, 7].sample(3).each do |weekday|
      user.availability_windows.create!(weekday:, start_minute: 18 * 60, end_minute: 21 * 60)
    end

    2.times do
      user.pair_requests.create!(
        subject: Faker::ProgrammingLanguage.name,
        description: Faker::Hacker.say_something_smart,
        duration: [30, 45, 60, 90, 120, 150].sample
      )
    end

    user
  end

  posters.each do |poster|
    pr1, pr2 = poster.pair_requests
    offerers = posters.excluding(poster).sample(10)

    # Each offer books its own slot from the poster's weekly hours.
    { pr1 => offerers.first(5), pr2 => offerers.last(5) }.each do |pair_request, request_offerers|
      request_offerers.zip(pair_request.bookable_slots.sample(request_offerers.size)).each do |offerer, slot|
        next unless slot

        offer = pair_request.offers.build(offerer:, message: Faker::Hacker.say_something_smart)
        offer.build_period(start_at: slot.start_at)
        offer.save!(context: :booking)
      end
    end

    Offers::Accept.call(pr1.offers.first) if pr1.offers.any?
  end
end
