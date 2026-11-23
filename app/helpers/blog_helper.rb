module BlogHelper
  def blog_posting_json_ld(post)
    pairin = { "@type": "Organization", name: "Pairin", url: canonical_url("/") }

    {
      "@context": "https://schema.org",
      "@type": "BlogPosting",
      headline: post.title,
      description: post.description,
      datePublished: post.date.iso8601,
      dateModified: post.last_modified.iso8601,
      url: canonical_url(blog_post_path(post)),
      mainEntityOfPage: canonical_url(blog_post_path(post)),
      image: image_url("og-default.png"),
      author: pairin,
      publisher: pairin.merge(logo: image_url("logo.png"))
    }.to_json
  end
end
