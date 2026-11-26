require "rails_helper"

RSpec.describe "Blog", type: :request do
  let(:post_slug) { "what-is-pair-programming" }

  describe "the list" do
    it "lists posts newest first with their title, date and description" do
      get blog_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<h1", ">Blog</h1>")
      expect(response.body).to include("What Is Pair Programming? A Guide for Solo Learners")
      expect(response.body).to include(%(href="/blog/#{post_slug}"))
      expect(response.body).to include("November 24, 2026")
      expect(response.body).to include("<title>Blog - Pairin</title>")
    end

    it "links the Atom feed for feed readers and dev.to" do
      get blog_path

      expect(response.body).to include('type="application/atom+xml"', 'href="https://pairin.dev/blog/feed.xml"')
    end
  end

  describe "a post" do
    it "renders the markdown server-side with the post's own meta tags" do
      get blog_post_path(post_slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<title>What Is Pair Programming? A Guide for Solo Learners - Pairin</title>")
      expect(response.body).to include('<meta name="description" content="What pair programming is, where it came from, the main styles')
      expect(response.body).to include('<meta property="og:type" content="article">')
      expect(response.body).to include('<meta property="og:title" content="What Is Pair Programming? A Guide for Solo Learners - Pairin">')
      expect(response.body).to include(%(<link rel="canonical" href="https://pairin.dev/blog/#{post_slug}">))
      expect(response.body).to match(%r{<h2[^>]*>Types of pair programming})
      expect(response.body).to include("Pairin team")
    end

    it "ends with the sign-up sign-off" do
      get blog_post_path(post_slug)

      expect(response.body).to include("Find a partner &rarr;", 'href="/users/sign_up"')
    end

    it "has BlogPosting structured data with Pairin as author" do
      get blog_post_path(post_slug)

      scripts = Nokogiri::HTML(response.body).css('script[type="application/ld+json"]').map { |s| JSON.parse(s.text) }
      posting = scripts.find { |data| data["@type"] == "BlogPosting" }

      expect(posting).to include(
        "headline" => "What Is Pair Programming? A Guide for Solo Learners",
        "datePublished" => "2026-11-24",
        "url" => "https://pairin.dev/blog/#{post_slug}"
      )
      expect(posting["author"]).to include("@type" => "Organization", "name" => "Pairin")
    end

    it "returns 404 for a post that doesn't exist" do
      get "/blog/no-such-post"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "the feed" do
    it "is an Atom feed with each post and its canonical link" do
      get "/blog/feed.xml"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/atom+xml")

      feed = Nokogiri::XML(response.body).remove_namespaces!
      expect(feed.css("entry").size).to eq(BlogPost.all.size)
      entry = feed.css("entry").find { |e| e.at("link")["href"].end_with?("/#{post_slug}") }
      expect(entry.at("title").text).to eq("What Is Pair Programming? A Guide for Solo Learners")
      expect(entry.at("link")["href"]).to eq("https://pairin.dev/blog/#{post_slug}")
      expect(entry.at("content").text).to include("Driver and navigator")
    end
  end

  describe "the sitemap" do
    it "lists the main pages, the blog and every post" do
      get "/sitemap.xml"

      expect(response).to have_http_status(:ok)
      locs = Nokogiri::XML(response.body).remove_namespaces!.css("url loc").map(&:text)
      expect(locs).to contain_exactly(
        "https://pairin.dev/",
        "https://pairin.dev/blog",
        *BlogPost.all.map { |post| "https://pairin.dev/blog/#{post.slug}" },
        "https://pairin.dev/privacy",
        "https://pairin.dev/terms"
      )
      expect(locs).to include("https://pairin.dev/blog/#{post_slug}")
    end
  end

  describe "the homepage" do
    it "links to the blog from the footer" do
      get "/"

      expect(response.body).to include(%(href="/blog"))
    end

    it "links to the source code from the footer, as the AGPL license expects" do
      get "/"

      expect(response.body).to include(%(href="https://github.com/JovicaSusa/pairin-dev"), ">Source code</a>")
    end

    it "shares a PNG card and a plain apostrophe in the description" do
      get "/"

      expect(response.body).to include('<html lang="en">')
      expect(response.body).to include("commit when it&#39;s a good fit")
      expect(response.body).not_to include("&amp;#39;")
      expect(response.body).to match(%r{<meta property="og:image" content="[^"]+og-default[^"]*\.png">})
      expect(response.body).to include('<meta name="twitter:card" content="summary_large_image">')
    end
  end
end

RSpec.describe BlogPost do
  it "reads every file in content/blog, with the slug from the filename" do
    post = described_class.find_by_slug("what-is-pair-programming")

    expect(post.title).to eq("What Is Pair Programming? A Guide for Solo Learners")
    expect(post.date).to eq(Date.new(2026, 11, 24))
    expect(post.last_modified).to eq(post.date)
  end

  it "has no raw HTML in the rendered markdown" do
    post = described_class.new(slug: "x", title: "x", description: "x", date: Date.current, body: "<script>alert(1)</script>\n\nHi")

    expect(post.html).not_to include("<script>")
  end
end
