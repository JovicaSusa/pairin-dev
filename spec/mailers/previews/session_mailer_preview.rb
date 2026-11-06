# Preview all emails at http://localhost:3000/rails/mailers/session_mailer
class SessionMailerPreview < ActionMailer::Preview
  def proposed_email
    SessionMailer.with(session: Session.last).proposed_email
  end
end
