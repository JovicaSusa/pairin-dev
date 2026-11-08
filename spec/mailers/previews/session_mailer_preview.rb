# Preview all emails at http://localhost:3000/rails/mailers/session_mailer
class SessionMailerPreview < ActionMailer::Preview
  def proposed_email
    SessionMailer.with(session: session("proposed")).proposed_email
  end

  %i[confirmed declined withdrawn cancelled].each do |action|
    define_method(:"#{action}_email") do
      SessionMailer.with(session: session(action.to_s), by: actor(action)).public_send(:"#{action}_email")
    end
  end

  # An unsaved answer, so the preview creates nothing. Its token can't be
  # checked, but the email renders.
  def did_it_happen_email
    session = Session.last
    answer = SessionAnswer.new(session:, user: session.proposed_by)
    SessionMailer.with(session:, answer:).did_it_happen_email
  end

  def reminder_email
    session = session("confirmed")
    SessionMailer.with(session:, recipient: session.proposed_by).reminder_email
  end

  private

  # The mailer sends nothing unless the session is in the state the email
  # describes, so set it in memory (never saved) for the preview.
  def session(status)
    Session.last.tap { |s| s.status = status }
  end

  def actor(action)
    proposer = Session.last.proposed_by
    action == :withdrawn ? proposer : Session.last.partnership.offer.other_person(proposer)
  end
end
