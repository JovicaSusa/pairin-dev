FactoryBot.define do
  factory(:offer) do
    offerer factory: :user

    message { Faker::Lorem.sentence(word_count: 5) }

    after(:build) do |offer|
      pair_request = create(:pair_request)
      period = create(:period, periodable: pair_request)

      offer.pair_request = pair_request if offer.pair_request.nil?
      offer.period = period if offer.period.nil?
    end
  end
end
