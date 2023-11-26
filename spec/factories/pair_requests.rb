FactoryBot.define do
  factory(:pair_request) do
    user

    subject { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.sentence(word_count: 33) }
  end
end
