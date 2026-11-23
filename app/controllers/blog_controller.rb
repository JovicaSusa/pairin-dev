class BlogController < ApplicationController
  layout "marketing"

  def index
    @posts = BlogPost.all
  end

  def show
    @post = BlogPost.find_by_slug(params[:slug])
    raise ActionController::RoutingError, "Not Found" unless @post
  end

  def feed
    @posts = BlogPost.all
    render layout: false, content_type: "application/atom+xml"
  end
end
