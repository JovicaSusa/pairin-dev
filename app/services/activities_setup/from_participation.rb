module ActivitiesSetup
  class FromParticipation
    attr_reader :record
    private :record

    def initialize(record)
      @record = record
    end

    def self.call(...) = new(...).call

    def call
      Activity.create!(
        receiver: record.participant,
        title: I18n.t("activities.session_scheduled.titles").sample,
        content: I18n.t("activities.session_scheduled.content").sample
      )
    end
  end
end
