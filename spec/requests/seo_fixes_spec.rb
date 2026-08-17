require "rails_helper"

RSpec.describe "SEO fixes", type: :request do
  it "renders real server-side content on the homepage, not an empty Inertia shell" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("A place where")
    expect(response.body).to include("programmers")
    expect(response.body).not_to include('data-page="{')
  end

  it "includes a canonical tag pointing at the non-www host" do
    get "/"

    expect(response.body).to include('<link rel="canonical" href="https://pairin.dev/">')
  end

  it "includes FAQPage structured data server-side" do
    get "/"

    expect(response.body).to include('"@type":"FAQPage"')
  end

  it "redirects www to the canonical non-www host" do
    get "/", headers: { "HOST" => "www.pairin.dev" }

    expect(response).to have_http_status(:moved_permanently)
    expect(response.headers["Location"]).to eq("https://pairin.dev/")
  end

  it "serves the privacy and terms pages" do
    get "/privacy"
    expect(response).to have_http_status(:ok)

    get "/terms"
    expect(response).to have_http_status(:ok)
  end
end
