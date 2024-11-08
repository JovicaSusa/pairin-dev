module ActivitiesSetup
  class Proxy
    attr_reader :record
    private :record

    def initialize(record)
      @record = record
    end

    def self.call(...) = new(...).call

    def call
      ActivitiesSetup.const_get("From#{record.class}").call(record)
    end
  end
end
