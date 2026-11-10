FactoryBot.define do
  factory(:user) do
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    confirmed_at { 1.day.ago }
    date_of_birth { Date.new(1990, 6, 15) }
    name { Faker::Name.first_name }
    level { "novice" }
  end
end
