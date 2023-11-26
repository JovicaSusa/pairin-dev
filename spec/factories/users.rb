FactoryBot.define do
  factory(:user) do
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    confirmed_at { 1.day.ago }
  end
end
