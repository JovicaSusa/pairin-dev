require 'rails_helper'

RSpec.describe "Users::PairRequests extend_wait", type: :request do
  describe "PATCH /users/pair_requests/:id/extend_wait" do
    let(:current_user) { create(:user) }
    let(:pair_request) { create(:pair_request, :immediate, user: current_user, wait_minutes: 30) }

    before { sign_in(current_user) }

    it "extends the wait and redirects with a notice" do
      freeze_time do
        patch extend_wait_users_pair_request_path(pair_request)

        expect(pair_request.periods.first.reload.start_at).to eq(Time.current)
        expect(response).to redirect_to(users_pair_requests_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when the pair request already has an accepted offer" do
      before { create(:offer, :accepted, pair_request:) }

      it "redirects with an alert and doesn't change the period" do
        expect {
          patch extend_wait_users_pair_request_path(pair_request)
        }.not_to change { pair_request.periods.first.reload.start_at }

        expect(response).to redirect_to(users_pair_requests_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when the pair request belongs to another user" do
      let(:pair_request) { create(:pair_request, :immediate, wait_minutes: 30) }

      it "404s, since it is scoped to the current user's own pair requests (matching add_call_link)" do
        patch extend_wait_users_pair_request_path(pair_request)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the pair request is scheduled mode" do
      let(:pair_request) { create(:pair_request, user: current_user) }

      it "is not authorized" do
        patch extend_wait_users_pair_request_path(pair_request)

        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to be_present
      end
    end
  end
end
