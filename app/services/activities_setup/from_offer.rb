module ActivitiesSetup
  class FromOffer
    attr_reader :record, :previous_changes
    private :record, :previous_changes

    def initialize(record, previous_changes)
      @record = record
      @previous_changes = previous_changes
    end

    def self.call(...) = new(...).call

    def call
      if previously_created?
        generate_offer_sent_and_offer_received_activities
      elsif previously_accepted?
        generate_offer_accepted_and_offer_rejected_activities
      end
    end

    private

    delegate :pair_request, :offerer, to: :record

    def generate_offer_sent_and_offer_received_activities
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
    end

    def generate_offer_accepted_and_offer_rejected_activities
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

    def previously_created?
      previous_changes.key?(:id)
    end

    def previously_accepted?
      previous_changes.key?(:accepted_at) && previous_changes[:accepted_at].first.nil?
    end
  end
end
