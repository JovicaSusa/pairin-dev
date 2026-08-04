require "rails_helper"

RSpec.describe "SessionSummaries", type: :request do
  describe "GET /index" do
    subject(:index) { get session_summaries_path }

    let(:current_user) { create(:user) }

    before { sign_in current_user }

    it "returns http success" do
      index

      expect(response).to have_http_status(:success)
    end

    context "when the current user is not a participant of the completed session" do
      let!(:session) { create(:session, :past) }

      it "still includes the session's pair request" do
        index

        expect(response.body).to include(session.sessionable.subject)
      end
    end
  end
end
