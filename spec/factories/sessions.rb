FactoryBot.define do
  factory(:session) do
    sessionable factory: :pair_request
    start_at { 45.minutes.from_now }
    end_at { 115.minutes.from_now }

    after(:create) do |session, evaluator|
      pair_request = session.sessionable
      offer = create(:offer, :accepted, pair_request: session.sessionable)
      create(:participation, participant: pair_request.user, participable: session)
      create(:participation, participant: offer.offerer, participable: session)
    end
  end
end
