# A resource in a Workspace: a link with an optional note that either partner
# can add or remove. Only web links, since the URL ends up in an href.
class SharedLink < ApplicationRecord
  URL_MAX_LENGTH = 2000
  NOTE_MAX_LENGTH = 500

  belongs_to :partnership
  belongs_to :added_by, class_name: "User"

  normalizes :url, with: ->(url) { url.strip }
  normalizes :note, with: ->(note) { note.strip.presence }

  validates :url, presence: true, length: { maximum: URL_MAX_LENGTH }
  validates :note, length: { maximum: NOTE_MAX_LENGTH }
  validate :url_is_a_web_link

  # The site's name, for showing a link compactly: "github.com".
  def host
    URI.parse(url).host.delete_prefix("www.")
  end

  private

  def url_is_a_web_link
    return if url.blank?

    uri = URI.parse(url)
    errors.add(:url, "must start with http:// or https://") unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:url, "isn't a valid link")
  end
end
