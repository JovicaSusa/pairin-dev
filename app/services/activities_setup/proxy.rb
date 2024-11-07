module ActivitiesSetup
  class Proxy
    attr_reader :record, :previous_changes
    private :record, :previous_changes

    def initialize(record, previous_changes)
      @record = record
      @previous_changes = previous_changes
    end

    def self.call(...) = new(...).call

    def call
      ActivitiesSetup.const_get("From#{record.class}").call(record, previous_changes)
    end
  end
end
