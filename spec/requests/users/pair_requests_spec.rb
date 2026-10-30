require 'rails_helper'

RSpec.describe "Users::PairRequests", type: :request do
  let(:poster) { create(:user) }
  let(:pair_request) { create(:pair_request, user: poster) }

  before { sign_in(poster) }

  describe "posting a request" do
    let(:params) { { subject: "Learn Rust", description: "Ownership and borrowing", duration: 60 } }

    context "without weekly hours" do
      it "sends the poster to add weekly hours first, from the form" do
        get new_users_pair_request_path

        expect(response).to redirect_to(availability_path)
        expect(flash[:alert]).to eq("Add your weekly hours first. Others book your requests into them.")
      end

      it "saves nothing when posted anyway" do
        expect { post users_pair_requests_path, params: }.not_to change(PairRequest, :count)

        expect(response).to redirect_to(availability_path)
      end
    end

    context "with weekly hours" do
      before { create(:availability_window, user: poster) }

      it "posts the request switched on, without time slots of its own" do
        expect { post users_pair_requests_path, params: }.to change(poster.pair_requests, :count).by(1)

        expect(poster.pair_requests.last).not_to be_paused
        expect(Period.where(periodable: poster.pair_requests.last)).to be_empty
      end

      it "refuses a call longer than 3 hours" do
        expect { post users_pair_requests_path, params: params.merge(duration: 240) }.not_to change(PairRequest, :count)

        expect(session[:inertia_errors]).to include(:duration)
      end
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

    it "keeps it off while the poster has no weekly hours" do
      poster.availability_windows.destroy_all

      patch resume_users_pair_request_path(pair_request)

      expect(pair_request.reload).to be_paused
      expect(flash[:alert]).to eq("Add your weekly hours before switching a request on. Others book your requests into them.")
    end
  end
end
