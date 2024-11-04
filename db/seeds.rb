# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Array.new(20) { Faker::Internet.email }.map do |email|
  user = User.create!(email: email, confirmed_at: Time.zone.now, password: "Password33*")

  user.pair_requests.create!(
    subject: Faker::ProgrammingLanguage.name,
    description: Faker::Hacker.say_something_smart,
    duration: rand(30..120)
  )
end

PairRequest.all.map do |pr|
  pr.periods.create!(
    start_at: Time.zone.now.advance(days: rand(1..30))
  )

  users = User.where.not(id: pr.user_id).sample(10)

  users.map do |user|
    pr.offers.create!(offerer: user, message: Faker::Hacker.say_something_smart, period: pr.periods.future.first)
  end
end
