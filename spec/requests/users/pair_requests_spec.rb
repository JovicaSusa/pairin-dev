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
