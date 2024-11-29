FactoryBot.define do
  factory(:pair_request) do
    transient do
      with_periods { true }
    end

    user

    subject { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.sentence(word_count: 33) }
    duration { Faker::Number.between(from: 1, to: 90) }

    after(:create) do |pair_request, evaluator|
      create(:period, periodable: pair_request) if pair_request.periods.blank? && evaluator.with_periods
    end
  end
end
