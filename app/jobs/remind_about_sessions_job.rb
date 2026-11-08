# Runs every few minutes, so reminders arrive about an hour before each session.
class RemindAboutSessionsJob < ApplicationJob
  queue_as :default

  def perform
    Session.remind_about_upcoming
  end
end
