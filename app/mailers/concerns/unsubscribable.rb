# For optional emails: the footer link, plus the headers that let mail apps offer
# a one-click unsubscribe. Call it before `mail`.
module Unsubscribable
  extend ActiveSupport::Concern

  private

  def allow_unsubscribe(user, category)
    @unsubscribe_url = unsubscribe_url(category:, token: user.unsubscribe_token(category))

    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
  end
end
