# For pages reached from an emailed, signed link (no login). The token in the
# URL works like a password: keep it out of referrers (to any page, ours
# included, since our other pages load analytics), caches and search indexes.
module NoLoginTokenPage
  extend ActiveSupport::Concern

  included do
    layout "token_page"

    before_action :protect_token

    # With "no-referrer", browsers send `Origin: null` on the page's own form
    # POSTs, and Rails' origin check rejects them (422). Skip only that check:
    # the authenticity token is still verified, and every POST needs the
    # signed token from the URL too.
    self.forgery_protection_origin_check = false
  end

  private

  def protect_token
    response.set_header("Referrer-Policy", "no-referrer")
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    response.headers["Cache-Control"] = "no-store"
  end
end
