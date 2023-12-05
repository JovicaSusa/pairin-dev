FactoryBot.define do
  factory(:pair_request) do
    user

    subject { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.sentence(word_count: 33) }
    duration { Faker::Number.between(from: 1, to: 90) }

    after(:create) do |pair_request, evaluator|
      create(:period, periodable: pair_request)
    end
  end
end
