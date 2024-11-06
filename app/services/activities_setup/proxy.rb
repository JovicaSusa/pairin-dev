module ActivitiesSetup
  class Proxy
    attr_reader :record
    private :record

    HANDLERS = {
      PairRequest => FromPairRequest,
      Offer => FromOffer,
      Participation => FromParticipation
    }.freeze

    def initialize(record)
      @record = record
    end

    def self.call(...) = new(...).call

    def call
      HANDLERS[record.class].call(record)
    end
  end
end
