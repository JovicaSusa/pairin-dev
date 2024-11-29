# Preview all emails at http://localhost:3000/rails/mailers/session
class SessionMailerPreview < ActionMailer::Preview
  def session_scheduled_email
    SessionMailer.with(session: Session.first, participant: User.find(12)).session_scheduled_email
  end
end
