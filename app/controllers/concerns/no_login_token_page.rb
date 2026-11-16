# For pages reached from an emailed, signed link (no login). The token in the
# URL works like a password: keep it out of referrers to other sites, caches and
# search indexes. "same-origin", not "no-referrer": with "no-referrer" browsers
# send `Origin: null` on the page's own form POSTs, and Rails rejects them (422).
module NoLoginTokenPage
  extend ActiveSupport::Concern

  included do
    layout "token_page"

    before_action :protect_token
  end

  private

  def protect_token
    response.set_header("Referrer-Policy", "same-origin")
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    response.headers["Cache-Control"] = "no-store"
  end
end
