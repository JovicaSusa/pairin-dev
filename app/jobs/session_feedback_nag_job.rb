class SessionFeedbackNagJob < ApplicationJob
  queue_as :default

  def perform(session_id)
    session = Session.find_by(id: session_id)
    return unless session

    session.participants.each do |participant|
      next if session.feedback_from(participant).present?

      Activity.create!(
        receiver: participant,
        title: I18n.t("activities.retro_nag.titles").sample,
        content: I18n.t("activities.retro_nag.content").sample
      )

      SessionMailer.with(session:, participant:).retro_nag_email.deliver_later
    end
  end
end
