FactoryBot.define do
  factory(:pair_request) do
    user

    subject { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.sentence(word_count: 33) }
    duration { Faker::Number.between(from: 1, to: 90) }

    # TODO: Fix this, when we create period, we create pair request with period, which is not always what we want
    after(:create) do |pair_request, evaluator|
      create(:period, periodable: pair_request) unless pair_request.periods.any?
    end
  end
end
