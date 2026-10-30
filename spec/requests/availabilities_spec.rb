require 'rails_helper'

RSpec.describe "Availability", type: :request do
  let(:user) { create(:user, timezone: "Europe/Berlin") }

  before { sign_in(user) }

  describe "GET /availability" do
    it "shows the user's own weekly hours and timezone" do
      create(:availability_window, user:, weekday: 2, start_minute: 18 * 60, end_minute: 20 * 60)
      create(:availability_window, weekday: 5, start_minute: 9 * 60, end_minute: 10 * 60)

      get availability_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Europe/Berlin")
      expect(response.body).to include("&quot;weekday&quot;:2")
      expect(response.body).not_to include("&quot;weekday&quot;:5")
    end
  end

  describe "POST /availability/windows" do
    it "adds a weekly window" do
      expect {
        post availability_windows_path, params: { weekday: 2, start_minute: 18 * 60, end_minute: 20 * 60 }
      }.to change(user.availability_windows, :count).by(1)

      expect(response).to redirect_to(availability_path)
    end

    it "rejects a window that ends before it starts" do
      expect {
        post availability_windows_path, params: { weekday: 2, start_minute: 20 * 60, end_minute: 18 * 60 }
      }.not_to change(AvailabilityWindow, :count)

      expect(session[:inertia_errors]).to include(:end_minute)
    end
  end

  describe "DELETE /availability/windows/:id" do
    it "removes the user's own window" do
      window = create(:availability_window, user:)

      expect { delete availability_window_path(window) }.to change(AvailabilityWindow, :count).by(-1)
    end

    it "can't remove someone else's window" do
      window = create(:availability_window)

      delete availability_window_path(window)

      expect(response).to have_http_status(:not_found)
      expect(AvailabilityWindow.exists?(window.id)).to be(true)
    end
  end

  describe "PATCH /availability" do
    it "saves a real timezone" do
      patch availability_path, params: { timezone: "Asia/Tokyo" }

      expect(user.reload.timezone).to eq("Asia/Tokyo")
    end

    it "rejects a made-up timezone" do
      patch availability_path, params: { timezone: "Mars/Olympus_Mons" }

      expect(user.reload.timezone).to eq("Europe/Berlin")
      expect(session[:inertia_errors]).to include(:timezone)
    end
  end
end
