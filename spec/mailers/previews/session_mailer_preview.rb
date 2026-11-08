# Preview all emails at http://localhost:3000/rails/mailers/session_mailer
class SessionMailerPreview < ActionMailer::Preview
  def proposed_email
    SessionMailer.with(session: Session.last).proposed_email
  end

  def confirmed_email = changed("confirmed")
  def declined_email = changed("declined")
  def withdrawn_email = changed("withdrawn")
  def cancelled_email = changed("cancelled")

  private

  # The partner who didn't propose it answers; the proposer withdraws.
  def changed(change)
    session = Session.last
    by = change == "withdrawn" ? session.proposed_by : session.partnership.offer.other_person(session.proposed_by)
    SessionMailer.with(session:, by:, change:).changed_email
  end
end
