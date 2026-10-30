FactoryBot.define do
  factory(:offer) do
    transient do
      with_period { true }
    end

    offerer factory: :user

    message { Faker::Lorem.sentence(word_count: 5) }

    trait :accepted do
      accepted_at { Time.current }
    end

    after(:build) do |offer, evaluator|
      offer.pair_request ||= create(:pair_request)

      if evaluator.with_period && offer.period.nil?
        offer.period = build(:period, periodable: offer, start_at: 30.minutes.from_now)
      end
    end
  end
end
