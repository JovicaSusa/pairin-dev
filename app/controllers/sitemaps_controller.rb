# Replaces the hand-written public/sitemap.xml, so new blog posts are listed
# without anyone remembering to add them.
class SitemapsController < ApplicationController
  def show
    @posts = BlogPost.all
    render layout: false, content_type: "application/xml"
  end
end
