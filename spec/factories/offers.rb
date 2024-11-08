FactoryBot.define do
  factory(:offer) do
    offerer factory: :user
    pair_request
    period_id { pair_request.periods.first&.id }

    message { Faker::Lorem.sentence(word_count: 5) }

    trait :accepted do
      accepted_at { Time.current }
    end
  end
end
