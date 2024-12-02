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
  Array.new(20) { Faker::Internet.email }.map do |email|
    user = User.create!(email: email, confirmed_at: Time.zone.now, password: "Password33*")

    user.pair_requests.create!(
      subject: Faker::ProgrammingLanguage.name,
      description: Faker::Hacker.say_something_smart,
      duration: [30, 45, 60, 90, 120, 150].sample
    )
    user.pair_requests.create!(
      subject: Faker::ProgrammingLanguage.name,
      description: Faker::Hacker.say_something_smart,
      duration: [30, 45, 60, 90, 120, 150].sample
    )
  end

  User.all.map do |user|
    pr1, pr2 = user.pair_requests

    pr1.periods.create!(
      start_at: Time.zone.now.advance(days: rand(1..30))
    )
    pr2.periods.create!(
      start_at: Time.zone.now.advance(days: rand(1..30))
    )

    users = User.where.not(id: pr.user_id).sample(10)

    users.first(5).map do |user|
      pr1.offers.create!(offerer: user, message: Faker::Hacker.say_something_smart, period: pr1.periods.future.first)
    end
    users.last(5).map do |user|
      pr2.offers.create!(offerer: user, message: Faker::Hacker.say_something_smart, period: pr2.periods.future.first)
    end

    Offers::Accept.call(pr1.offers.first)
  end
end
