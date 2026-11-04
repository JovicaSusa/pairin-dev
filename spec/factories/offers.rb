FactoryBot.define do
  factory(:offer) do
    transient do
      with_old_period { false }
    end

    offerer factory: :user

    message { Faker::Lorem.sentence(word_count: 5) }

    trait :accepted do
      accepted_at { Time.current }
    end

    after(:build) do |offer, evaluator|
      offer.pair_request ||= create(:pair_request)

      # Applications used to book a time; some old ones still have one.
      if evaluator.with_old_period && offer.period.nil?
        offer.period = build(:period, periodable: offer, start_at: 30.minutes.from_now, end_at: 90.minutes.from_now)
      end
    end
  end
end
