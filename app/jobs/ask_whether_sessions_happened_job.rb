# Runs every few minutes, so "Did it happen?" arrives shortly after a session ends.
class AskWhetherSessionsHappenedJob < ApplicationJob
  queue_as :default

  def perform
    Session.ask_whether_they_happened
  end
end
