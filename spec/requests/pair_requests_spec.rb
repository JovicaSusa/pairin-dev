require 'rails_helper'

RSpec.describe "PairRequests", type: :request do
  describe "GET /pair_requests" do
    before { sign_in(create(:user)) }

    it "lists requests that are on and leaves out requests that are off" do
      create(:pair_request, subject: "Switched on request")
      create(:pair_request, subject: "Switched off request", paused_at: 1.hour.ago)

      get pair_requests_path

      expect(response.body).to include("Switched on request")
      expect(response.body).not_to include("Switched off request")
    end
  end
end
