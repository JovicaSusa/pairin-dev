module ActivitiesSetup
  class FromOffer
    attr_reader :record
    private :record

    def initialize(record)
      @record = record
    end

    def self.call(...) = new(...).call

    def call
      if record.previously_new_record?
        Activity.create!(
          receiver: record.offerer,
          title: ["Your offer has been sent, good luck", "You are first one to make an offer to..., good luck"].sample,
          content: "We have sent an offer"
        )

        Activity.create!(
          receiver: record.pair_request.user,
          title: ["Offer incoming", "New Offer for ya", "We told you, you'l have an offer soon. And guess what"].sample,
          content: "You have received an offer"
        )
      else
        return unless record.accepted_at_previously_changed?(from: nil)

        Activity.create!(
          receiver: record.offerer,
          title: ["Your offer just got accepted", "Way the go, you're offer just got accepted"].sample,
          content: "Happy Pairin! Have fun"
        )

        pair_request.offers.excluding(self).each do |offer|
          Activity.create!(
            receiver: offer.offerer,
            title: ["Ouch", "Better luck next time"].sample,
            content: "Sorry, but this and that"
          )
        end
      end

    end
  end
end
