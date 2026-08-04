require 'rails_helper'

RSpec.describe "Users::PairRequests reschedule", type: :request do
  describe "PATCH /users/pair_requests/:id/reschedule" do
    let(:current_user) { create(:user) }
    let(:pair_request) { create(:pair_request, :immediate, user: current_user, wait_minutes: 30) }
    let(:new_start_at) { 3.days.from_now }
    let(:params) { { pair_request: { periods_attributes: [{ start_at: new_start_at }] } } }

    before { sign_in(current_user) }

    it "flips the mode to scheduled, replaces the period, and redirects with a notice" do
      patch reschedule_users_pair_request_path(pair_request), params: params

      pair_request.reload
      expect(pair_request.mode).to eq("scheduled")
      expect(pair_request.periods.first.start_at).to be_within(1.second).of(new_start_at)
      expect(response).to redirect_to(users_pair_requests_path)
      expect(flash[:notice]).to be_present
    end

    context "when the pair request already has an accepted offer" do
      before { create(:offer, :accepted, pair_request:) }

      it "redirects with an alert and doesn't change the mode" do
        expect {
          patch reschedule_users_pair_request_path(pair_request), params: params
        }.not_to change { pair_request.reload.mode }

        expect(response).to redirect_to(users_pair_requests_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when the pair request belongs to another user" do
      let(:pair_request) { create(:pair_request, :immediate, wait_minutes: 30) }

      it "404s, since it is scoped to the current user's own pair requests (matching add_call_link)" do
        patch reschedule_users_pair_request_path(pair_request), params: params

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the pair request is scheduled mode" do
      let(:pair_request) { create(:pair_request, user: current_user) }

      it "is not authorized" do
        patch reschedule_users_pair_request_path(pair_request), params: params

        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to be_present
      end
    end
  end
end
