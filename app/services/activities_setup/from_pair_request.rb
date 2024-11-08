module ActivitiesSetup
  class FromPairRequest
    attr_reader :record
    private :record

    def initialize(record)
      @record = record
    end

    def self.call(...) = new(...).call

    def call
      Activity.create!(
        receiver: record.user,
        title: I18n.t("activities.pair_request_created.titles").sample,
        content: I18n.t("activities.pair_request_created.content").sample
      )
    end
  end
end
