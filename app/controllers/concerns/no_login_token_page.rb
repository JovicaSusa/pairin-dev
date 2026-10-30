# For pages reached from an emailed, signed link (no login). The token in the
# URL works like a password: keep it out of referrers, caches and search indexes.
module NoLoginTokenPage
  extend ActiveSupport::Concern

  included do
    layout "marketing"

    before_action :protect_token
  end

  private

  def protect_token
    response.set_header("Referrer-Policy", "no-referrer")
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    response.headers["Cache-Control"] = "no-store"
  end
end
