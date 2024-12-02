FactoryBot.define do
  factory(:offer) do
    offerer factory: :user

    message { Faker::Lorem.sentence(word_count: 5) }

    trait :accepted do
      accepted_at { Time.current }
    end

    after(:build) do |offer|
      if offer.pair_request.nil?
        pair_request = create(:pair_request)
        offer.pair_request = pair_request
      end

      if offer.period.nil?
        offer.period = create(:period, periodable: offer.pair_request)
      end
    end
  end
end
