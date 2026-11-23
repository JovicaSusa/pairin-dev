xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc canonical_url("/")
    xml.changefreq "weekly"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc canonical_url(blog_path)
    xml.lastmod @posts.map(&:last_modified).max.iso8601 if @posts.any?
    xml.changefreq "weekly"
    xml.priority "0.7"
  end

  @posts.each do |post|
    xml.url do
      xml.loc canonical_url(blog_post_path(post))
      xml.lastmod post.last_modified.iso8601
      xml.priority "0.6"
    end
  end

  [ privacy_path, terms_path ].each do |path|
    xml.url do
      xml.loc canonical_url(path)
      xml.changefreq "yearly"
      xml.priority "0.3"
    end
  end
end
