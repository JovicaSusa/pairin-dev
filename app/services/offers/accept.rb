module Offers
  class Accept
    include Dry::Monads[:result]

    attr_reader :offer

    def initialize(offer) = @offer = offer

    def self.call(...) = new(...).call

    def call
      ApplicationRecord.transaction do
        offer.update!(accepted_at: Time.current)

        session = Session.create!(
          sessionable: pair_request,
          start_at: period.start_at,
          end_at: period.end_at)

        session.participations.create!(participant: offerer, role: Participation::ROLE_PAIR)
        session.participations.create!(participant: pair_request.user, role: Participation::ROLE_INITIATOR)
      end

      Success(offer)
    rescue ActiveRecord::RecordInvalid => e
      Failure(offer: offer, error: e)
    end

    private

    delegate :pair_request, :offerer, :period, to: :offer
  end
end
