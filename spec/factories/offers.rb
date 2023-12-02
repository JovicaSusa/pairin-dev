FactoryBot.define do
  factory(:offer) do
    offerer factory: :user
    pair_request
    period { association :period, periodable: pair_request }

    message { Faker::Lorem.sentence(word_count: 5) }
  end
end
