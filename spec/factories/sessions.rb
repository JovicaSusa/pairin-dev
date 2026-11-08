FactoryBot.define do
  factory(:session) do
    partnership do
      offer = create(:offer)
      offer.post_message(offer.pair_request.user, "Hi")
      offer.propose_partnership!(by: offer.offerer)
      offer.accept_proposal!(by: offer.pair_request.user)
    end
    proposed_by { partnership.offer.offerer }
    start_at { 2.days.from_now.change(min: 0) }
    end_at { start_at + 1.hour }
    # As confirm! would set it, for sessions created already confirmed.
    confirmed_at { Time.current if status == "confirmed" }
  end
end
