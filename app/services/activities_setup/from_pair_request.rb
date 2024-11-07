module ActivitiesSetup
  class FromPairRequest
    attr_reader :record, :previous_changes
    private :record, :previous_changes

    def initialize(record, previous_changes)
      @record = record
      @previous_changes = previous_changes
    end

    def self.call(...) = new(...).call

    def call
      return unless previously_created?

      Activity.create!(
        receiver: record.user,
        title: I18n.t("activities.pair_request_created.titles").sample,
        content: I18n.t("activities.pair_request_created.content").sample
      )
    end

    private

    def previously_created?
      previous_changes.key?(:id)
    end
  end
end
