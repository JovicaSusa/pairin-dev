require 'rails_helper'

RSpec.describe "PairRequests::Joins", type: :request do
  describe "POST /pair_requests/:pair_request_id/join" do
    let(:current_user) { create(:user) }
    let(:pair_request) { create(:pair_request, :immediate) }

    before { sign_in(current_user) }

    it "creates a session and redirects to sessions" do
      expect {
        post pair_request_join_path(pair_request)
      }.to change { Session.count }.by(1)

      expect(response).to redirect_to(sessions_path)
      expect(flash[:notice]).to be_present
    end

    context "when the pair request requires approval" do
      let(:pair_request) { create(:pair_request, :immediate, requires_approval: true) }

      it "does not authorize the join and redirects with an alert" do
        expect {
          post pair_request_join_path(pair_request)
        }.not_to change { Session.count }

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the pair request is scheduled (not immediate)" do
      let(:pair_request) { create(:pair_request) }

      it "does not authorize the join and redirects with an alert" do
        expect {
          post pair_request_join_path(pair_request)
        }.not_to change { Session.count }

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the current user owns the pair request" do
      let(:pair_request) { create(:pair_request, :immediate, user: current_user) }

      it "does not authorize the join and redirects with an alert" do
        expect {
          post pair_request_join_path(pair_request)
        }.not_to change { Session.count }

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the pair request has been cancelled" do
      let(:pair_request) { create(:pair_request, :immediate, :cancelled) }

      it "does not authorize the join and redirects with an alert" do
        expect {
          post pair_request_join_path(pair_request)
        }.not_to change { Session.count }

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the pair request is already matched" do
      before { create(:offer, :accepted, pair_request:) }

      it "redirects back to pair requests with an alert" do
        expect {
          post pair_request_join_path(pair_request)
        }.not_to change { Session.count }

        expect(response).to redirect_to(pair_requests_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
