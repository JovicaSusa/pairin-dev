require "dry/operation/extensions/active_record"

module Offers
  class Accept < Dry::Operation
    include Dry::Operation::Extensions::ActiveRecord

    def self.call(...) = new.call(...)

    def call(offer)
      session = transaction do
        step validate(offer)
        step accept_offer(offer)
        session = step schedule_session(offer)
      end

      inform_participants(session)
    end

    private

    def validate(offer)
      offer.pair_request.has_accepted_offer? ? Failure(:no_longer_acceptable) : Success()
    end

    def accept_offer(offer)
      offer.update!(accepted_at: Time.current)

      Success()
    rescue ActiveRecord::RecordInvalid => e
      Failure(offer: offer, error: e)
    end

    def schedule_session(offer)
      pair_request = offer.pair_request

      session = Session.create!(
        sessionable: pair_request,
        start_at: offer.period.start_at,
        end_at: offer.period.end_at
      )

      session.participations.create!(participant: offer.offerer, role: Participation::ROLE_PAIR)
      session.participations.create!(participant: pair_request.user, role: Participation::ROLE_INITIATOR)

      Success(session)
    rescue ActiveRecord::RecordInvalid => e
      Failure(offer: offer, error: e)
    end

    def inform_participants(session)
      session.participants.each do |participant|
        SessionMailer.with(
          session: session,
          participant: participant
        ).session_scheduled_email.deliver_later
      end
    end
  end
end
