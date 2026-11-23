atom_feed(root_url: "https://#{ApplicationController::CANONICAL_HOST}/blog", id: "tag:#{ApplicationController::CANONICAL_HOST},2026:/blog") do |feed|
  feed.title "Pairin blog"
  feed.subtitle "Guides on pair programming and learning to code with a partner."
  feed.updated @posts.map(&:last_modified).max&.to_time || Time.current

  @posts.each do |post|
    url = canonical_url(blog_post_path(post))
    feed.entry(post, url: url, id: "tag:#{ApplicationController::CANONICAL_HOST},#{post.date.iso8601}:/blog/#{post.slug}",
      published: post.date.to_time, updated: post.last_modified.to_time) do |entry|
      entry.title post.title
      entry.summary post.description
      entry.content post.html, type: "html"
      entry.author { |author| author.name "Pairin team" }
    end
  end
end
