require 'rails_helper'

RSpec.describe "Users::PairRequests", type: :request do
  let(:poster) { create(:user) }
  let(:pair_request) { create(:pair_request, user: poster) }

  before { sign_in(poster) }

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
