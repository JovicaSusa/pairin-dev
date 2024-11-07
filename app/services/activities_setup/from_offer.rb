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
          receiver: offerer,
          title: I18n.t("activities.sent_offer.titles").sample,
          content: I18n.t("activities.sent_offer.content").sample,
        )

        Activity.create!(
          receiver: pair_request.user,
          title: I18n.t("activities.received_offer.titles").sample,
          content: I18n.t("activities.received_offer.content").sample,
        )
      else
        return unless record.accepted_at_previously_changed?(from: nil)

        Activity.create!(
          receiver: offerer,
          title: I18n.t("activities.offer_accepted.titles").sample,
          content: I18n.t("activities.offer_accepted.content").sample,
        )

        pair_request.offers.excluding(record).each do |offer|
          Activity.create!(
            receiver: offer.offerer,
            title: I18n.t("activities.offer_not_accepted.titles").sample,
            content: I18n.t("activities.offer_not_accepted.content").sample,
          )
        end
      end
    end

    private

    delegate :pair_request, :offerer, to: :record
  end
end
