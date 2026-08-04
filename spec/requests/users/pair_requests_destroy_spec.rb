require 'rails_helper'

RSpec.describe "Users::PairRequests destroy", type: :request do
  describe "DELETE /users/pair_requests/:id" do
    let(:current_user) { create(:user) }
    let(:pair_request) { create(:pair_request, :immediate, user: current_user) }

    before { sign_in(current_user) }

    it "soft-cancels the request and redirects with a notice" do
      freeze_time do
        delete users_pair_request_path(pair_request)

        expect(pair_request.reload.cancelled_at).to eq(Time.current)
        expect(pair_request).to be_persisted
        expect(response).to redirect_to(users_pair_requests_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when the pair request already has an accepted offer" do
      before { create(:offer, :accepted, pair_request:) }

      it "redirects with an alert and doesn't cancel it" do
        expect {
          delete users_pair_request_path(pair_request)
        }.not_to change { pair_request.reload.cancelled_at }

        expect(response).to redirect_to(users_pair_requests_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when the pair request belongs to another user" do
      let(:pair_request) { create(:pair_request, :immediate) }

      it "404s, since it is scoped to the current user's own pair requests (matching add_call_link)" do
        delete users_pair_request_path(pair_request)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the pair request is scheduled mode" do
      let(:pair_request) { create(:pair_request, user: current_user) }

      it "still cancels it (cancel is allowed regardless of mode)" do
        delete users_pair_request_path(pair_request)

        expect(pair_request.reload.cancelled_at).to be_present
        expect(response).to redirect_to(users_pair_requests_path)
      end
    end
  end
end
