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
        title: ["Fix me"].sample,
        content: "Fix me, too"
      )
    end
  end
end
