# A blog post is a markdown file in content/blog/. A file there is live; drafts
# stay in docs/blog/ until they're moved in. The slug is the filename.
#
#   ---
#   title: What Is Pair Programming?
#   description: One or two sentences for search results and link previews.
#   date: 2026-11-24
#   updated: 2026-12-02   # optional
#   ---
#   Markdown body...
class BlogPost
  DIRECTORY = Rails.root.join("content/blog")
  FRONT_MATTER = /\A---\s*\n(?<yaml>.*?)\n---\s*\n(?<body>.*)\z/m

  attr_reader :slug, :title, :description, :date, :updated, :body

  class << self
    # Newest first. Read once per process in production, on every call
    # elsewhere so edits show up without a restart.
    def all
      return load_all unless Rails.env.production?

      @all ||= load_all
    end

    def find_by_slug(slug)
      all.find { |post| post.slug == slug }
    end

    def from_file(path)
      match = FRONT_MATTER.match(File.read(path))
      raise ArgumentError, "#{path} has no front matter" unless match

      data = YAML.safe_load(match[:yaml], permitted_classes: [ Date ])
      new(
        slug: File.basename(path, ".md"),
        title: data.fetch("title"),
        description: data.fetch("description"),
        date: data.fetch("date"),
        updated: data["updated"],
        body: match[:body]
      )
    end

    private

    def load_all
      Dir[DIRECTORY.join("*.md")].map { |path| from_file(path) }.sort_by(&:date).reverse
    end
  end

  def initialize(slug:, title:, description:, date:, body:, updated: nil)
    @slug = slug
    @title = title
    @description = description
    @date = date.to_date
    @updated = updated&.to_date
    @body = body
  end

  def last_modified
    updated || date
  end

  # The files are ours and reviewed in PRs, but raw HTML stays off anyway.
  def html
    Commonmarker.to_html(body, options: {
      extension: { table: true, strikethrough: true, autolink: true },
      render: { unsafe: false }
    }).html_safe
  end

  def to_param
    slug
  end
end
