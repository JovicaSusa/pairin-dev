require "rails_helper"

RSpec.describe "Workspace resources", type: :request do
  let(:poster) { create(:user, name: "Maya") }
  let(:partner) { create(:user, name: "Sam") }
  let(:search) { create(:pair_request, user: poster, subject: "Python buddy") }
  let!(:offer) { create(:offer, pair_request: search, offerer: partner, message: "Hi Maya") }
  let(:partnership) do
    offer.post_message(poster, "Great to meet you")
    offer.propose_partnership!(by: partner)
    offer.accept_proposal!(by: poster)
  end

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  def add(url:, note: "", partnership: self.partnership)
    post partner_resources_path(partnership), params: { url:, note: }
  end

  describe "adding" do
    it "lets either partner add a link with an optional note" do
      sign_in(poster)
      add(url: "https://docs.python.org/3/tutorial/", note: "Start with chapter 4")
      sign_in(partner)
      add(url: "https://exercism.org/tracks/python")

      expect(response).to redirect_to(partner_resources_path(partnership))
      expect(partnership.shared_links.pluck(:url, :note, :added_by_id)).to contain_exactly(
        ["https://docs.python.org/3/tutorial/", "Start with chapter 4", poster.id],
        ["https://exercism.org/tracks/python", nil, partner.id]
      )
    end

    it "refuses something that isn't a web link" do
      sign_in(poster)

      expect { add(url: "javascript:alert(1)") }.not_to change(SharedLink, :count)

      follow_redirect!
      expect(props.dig("errors", "url")).to eq("Link must start with http:// or https://")
    end

    it "signals the other partner" do
      partnership
      sign_in(poster)

      expect { add(url: "https://example.com") }.to have_broadcasted_to(partner).from_channel(ConversationsChannel)
    end
  end

  describe "the Resources page" do
    it "lists the links, newest first, with who added them" do
      partnership.shared_links.create!(added_by: partner, url: "https://www.github.com/sam/notes", note: "My notes", created_at: 1.day.ago)
      partnership.shared_links.create!(added_by: poster, url: "https://exercism.org")
      sign_in(poster)

      get partner_resources_path(partnership)

      expect(props.dig("partnership", "resources")).to match([
        a_hash_including("host" => "exercism.org", "note" => nil, "mine" => true),
        a_hash_including("url" => "https://www.github.com/sam/notes", "host" => "github.com", "note" => "My notes", "mine" => false)
      ])
      expect(props.dig("partnership", "conversation", "other", "name")).to eq("Sam")
    end
  end

  describe "the overview" do
    it "counts the links and shows the latest" do
      partnership.shared_links.create!(added_by: partner, url: "https://github.com/sam", created_at: 1.day.ago)
      partnership.shared_links.create!(added_by: poster, url: "https://www.exercism.org/tracks")
      sign_in(poster)

      get partner_path(partnership)

      expect(props.dig("partnership", "resources")).to eq("count" => 2, "latest" => "exercism.org")
    end
  end

  describe "removing" do
    it "lets either partner remove any link" do
      link = partnership.shared_links.create!(added_by: poster, url: "https://example.com")
      sign_in(partner)

      expect { delete partner_resource_path(partnership, link) }
        .to change(SharedLink, :count).by(-1)
        .and have_broadcasted_to(poster).from_channel(ConversationsChannel)
      expect(response).to redirect_to(partner_resources_path(partnership))
    end
  end

  describe "who can see them" do
    let(:outsider) { create(:user) }
    let!(:link) { partnership.shared_links.create!(added_by: poster, url: "https://example.com/private") }

    before { sign_in(outsider) }

    it "isn't anyone outside the partnership" do
      get partner_resources_path(partnership)

      expect(response).to have_http_status(:not_found)
    end

    it "doesn't let them add links" do
      add(url: "https://example.com/spam")

      expect(response).to have_http_status(:not_found)
      expect(partnership.shared_links.pluck(:url)).to eq(["https://example.com/private"])
    end

    it "doesn't let them remove links" do
      delete partner_resource_path(partnership, link)

      expect(response).to have_http_status(:not_found)
      expect(link.reload).to be_present
    end

    it "doesn't let a partner remove another partnership's link" do
      other_search = create(:pair_request, user: outsider)
      other_offer = create(:offer, pair_request: other_search, offerer: partner, message: "Hi")
      other_offer.post_message(outsider, "Hello")
      other_offer.propose_partnership!(by: partner)
      other_partnership = other_offer.accept_proposal!(by: outsider)
      sign_in(partner)

      delete partner_resource_path(other_partnership, link)

      expect(response).to have_http_status(:not_found)
      expect(link.reload).to be_present
    end
  end

  it "needs sign-in" do
    get partner_resources_path(partnership)

    expect(response).to redirect_to(new_user_session_path)
  end

  describe "once the partnership has ended" do
    let!(:link) { partnership.shared_links.create!(added_by: poster, url: "https://example.com") }

    before do
      partnership.end!(by: partner)
      sign_in(poster)
    end

    it "keeps the links readable" do
      get partner_resources_path(partnership)

      expect(props.dig("partnership", "ended")).to be(true)
      expect(props.dig("partnership", "resources").size).to eq(1)
    end

    it "doesn't let anyone add or remove them" do
      add(url: "https://example.com/late")
      expect(flash[:alert]).to eq("This partnership has ended.")

      delete partner_resource_path(partnership, link)
      expect(flash[:alert]).to eq("This partnership has ended.")

      expect(partnership.shared_links.pluck(:url)).to eq(["https://example.com"])
    end
  end

  it "goes with either person's account" do
    partnership.shared_links.create!(added_by: poster, url: "https://example.com")

    expect { poster.destroy! }.to change(SharedLink, :count).by(-1)
  end
end
