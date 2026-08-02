module ActivitiesSetup
  class FromSessionFeedback
    attr_reader :record, :previous_changes
    private :record, :previous_changes

    def initialize(record, previous_changes)
      @record = record
      @previous_changes = previous_changes
    end

    def self.call(...) = new(...).call

    def call
      return unless previously_created?

      other_participant = record.session.other_participant(record.participant)
      return unless other_participant

      Activity.create!(
        receiver: other_participant,
        title: I18n.t("activities.session_feedback_received.titles").sample,
        content: I18n.t("activities.session_feedback_received.content").sample
      )
    end

    private

    def previously_created?
      previous_changes.key?(:id)
    end
  end
end
