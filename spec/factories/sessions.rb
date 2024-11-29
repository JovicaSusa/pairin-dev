FactoryBot.define do
  factory(:session) do
    transient do
      with_participants { true }
    end

    sessionable factory: :pair_request
    start_at { 45.minutes.from_now }
    end_at { 115.minutes.from_now }

    after(:create) do |session, evaluator|
      if evaluator.with_participants
        pair_request = session.sessionable
        offer = create(:offer, :accepted, pair_request: session.sessionable)
        create(:participation, participant: pair_request.user, participable: session)
        create(:participation, participant: offer.offerer, participable: session)
      end
    end
  end
end
