# One person's answer to "Did you two work together this week?", for one week of
# a partnership. It's created when the email goes out, so it's unanswered until then.
class CheckIn < ApplicationRecord
  belongs_to :partnership
  belongs_to :user

  validates :week, numericality: { only_integer: true, greater_than: 0 }

  # Signed token for the no-login Yes/No links in the email.
  generates_token_for :answer, expires_in: 30.days

  def answer!(worked_together)
    update!(worked_together:, answered_at: Time.current)
  end

  def answered?
    answered_at?
  end
end
