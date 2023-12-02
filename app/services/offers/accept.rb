module Offers
  class Accept
    attr_reader :offer

    def initialize(offer) = @offer = offer

    def self.call(...) = new(...).call

    def call
      Offer.transaction do
        offer.update!(accepted_at: Time.current)

        session = pair_request.sessions.create!(start_at: selected_period.start_at, end_at: selected_period.end_at)
        # TODO: Try using insert_all ?
        session.participations.create!(participant: offerer, role: Participation::ROLE_PAIR)
        session.participations.create!(participant: pair_request.user, role: Participation::ROLE_INITIATOR)
      end
    end

    private

    delegate :pair_request, :offerer, :selected_period, to: :offer
  end
end
