require 'rails_helper'

RSpec.describe "Users::PairRequests", type: :request do
  let(:poster) { create(:user) }
  let(:pair_request) { create(:pair_request, user: poster) }

  before { sign_in(poster) }

  describe "posting a request" do
    let(:params) { { subject: "Learn Rust", description: "Ownership and borrowing", commitment: "open_ended" } }

    it "shows the form without weekly hours" do
      get new_users_pair_request_path

      expect(response).to have_http_status(:ok)
    end

    it "posts the request switched on, without weekly hours or time slots" do
      expect { post users_pair_requests_path, params: }.to change(poster.pair_requests, :count).by(1)

      expect(poster.pair_requests.last).not_to be_paused
      expect(Period.where(periodable: poster.pair_requests.last)).to be_empty
    end

    it "refuses a search with no subject" do
      expect { post users_pair_requests_path, params: params.merge(subject: "") }.not_to change(PairRequest, :count)

      expect(session[:inertia_errors]).to include(:subject)
    end
  end

  describe "editing a request" do
    let(:pair_request) { create(:pair_request, user: poster, subject: "Learn Rust", description: "Ownership", commitment: "few_weeks") }
    let!(:rust_tagging) { create(:tagging, taggable: pair_request, tag: create(:tag, name: "rust")) }

    def props
      JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
    end

    it "shows the form filled in with what's there now" do
      get edit_users_pair_request_path(pair_request)

      expect(response).to have_http_status(:ok)
      expect(props["pairRequest"]).to include("subject" => "Learn Rust", "description" => "Ownership", "commitment" => "few_weeks")
      expect(props["pairRequest"]["taggings"]).to eq([{ "id" => rust_tagging.id, "name" => "rust" }])
    end

    it "saves the changes and keeps the share link" do
      token = pair_request.share_token

      patch users_pair_request_path(pair_request), params: { subject: "Learn Go", description: "Goroutines", commitment: "open_ended" }

      expect(response).to redirect_to(users_pair_requests_path)
      expect(pair_request.reload).to have_attributes(subject: "Learn Go", description: "Goroutines", commitment: "open_ended", share_token: token)
    end

    it "removes and adds tags" do
      patch users_pair_request_path(pair_request), params: {
        taggings_attributes: [
          { id: rust_tagging.id, _destroy: "1", tag_attributes: { name: "rust" } },
          { tag_attributes: { name: "Go" } }
        ]
      }

      expect(pair_request.reload.tags.map(&:name)).to eq(["go"])
    end

    it "leaves offers already sent alone" do
      offer = create(:offer, pair_request:)

      patch users_pair_request_path(pair_request), params: { subject: "Learn Go" }

      expect(pair_request.reload.offers).to eq([offer])
    end

    it "refuses a blank subject and keeps the old one" do
      patch users_pair_request_path(pair_request), params: { subject: "" }

      expect(session[:inertia_errors]).to include(:subject)
      expect(pair_request.reload.subject).to eq("Learn Rust")
    end

    it "doesn't show someone else the form" do
      sign_in(create(:user))

      get edit_users_pair_request_path(pair_request)

      expect(response).to have_http_status(:not_found)
    end

    it "doesn't let someone else save changes" do
      sign_in(create(:user))

      patch users_pair_request_path(pair_request), params: { subject: "Hacked" }


      expect(response).to have_http_status(:not_found)
      expect(pair_request.reload.subject).to eq("Learn Rust")
    end

    it "doesn't touch another search's tags" do
      other_tagging = create(:tagging, taggable: create(:pair_request), tag: create(:tag, name: "elixir"))

      patch users_pair_request_path(pair_request), params: { taggings_attributes: [{ id: other_tagging.id, _destroy: "1" }] }

      expect(response).to have_http_status(:not_found)
      expect(Tagging.exists?(other_tagging.id)).to be(true)
    end
  end

  describe "PATCH /users/pair_requests/:id/pause" do
    it "switches the request off" do
      patch pause_users_pair_request_path(pair_request)

      expect(response).to redirect_to(users_pair_requests_path)
      expect(pair_request.reload).to be_paused
    end

    it "doesn't let someone else switch it off" do
      sign_in(create(:user))

      patch pause_users_pair_request_path(pair_request)

      expect(pair_request.reload).not_to be_paused
    end
  end

  describe "PATCH /users/pair_requests/:id/resume" do
    before { pair_request.update!(paused_at: 1.hour.ago) }

    it "switches the request back on" do
      patch resume_users_pair_request_path(pair_request)

      expect(response).to redirect_to(users_pair_requests_path)
      expect(pair_request.reload).not_to be_paused
    end
  end
end
