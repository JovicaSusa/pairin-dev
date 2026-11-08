# Preview all emails at http://localhost:3000/rails/mailers/session_mailer
class SessionMailerPreview < ActionMailer::Preview
  def proposed_email
    SessionMailer.with(session:).proposed_email
  end

  %i[confirmed declined withdrawn cancelled].each do |action|
    define_method(:"#{action}_email") do
      SessionMailer.with(session:, by: actor(action)).public_send(:"#{action}_email")
    end
  end

  private

  def session
    Session.last
  end

  def actor(action)
    proposer = session.proposed_by
    %i[withdrawn].include?(action) ? proposer : session.partnership.offer.other_person(proposer)
  end
end
