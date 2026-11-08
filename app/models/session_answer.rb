# One partner's answer to "Did it happen?" for one confirmed session. It's created
# when the email goes out, so it's unanswered until then, and answering again
# changes it.
class SessionAnswer < ApplicationRecord
  belongs_to :session
  belongs_to :user

  # Signed token for the no-login Yes/No links in the email.
  generates_token_for :answer, expires_in: 30.days

  # A Yes also records that week as worked together on the weekly check-in
  # (#234), even if the check-in has already gone out.
  def answer!(happened)
    transaction do
      update!(happened:, answered_at: Time.current)
      session.partnership.record_completed_session(session) if happened
    end
  end

  def answered?
    answered_at?
  end
end
