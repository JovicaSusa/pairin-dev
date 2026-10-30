require 'rails_helper'

RSpec.describe "PairRequests", type: :request do
  describe "GET /pair_requests" do
    # Monday 2 Nov 2026, 08:00 UTC.
    around { |example| travel_to(Time.utc(2026, 11, 2, 8, 0)) { example.run } }

    let(:viewer) { create(:user) }

    before { sign_in(viewer) }

    def listed_subjects(params = {})
      get pair_requests_path, params: params
      JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])
        .dig("props", "pairRequests").map { |request| request["subject"] }
    end

    def poster_free_on(weekday)
      create(:user).tap { |user| create(:availability_window, user:, weekday:, start_minute: 18 * 60, end_minute: 20 * 60) }
    end

    it "lists requests that are on and leaves out requests that are off" do
      create(:pair_request, subject: "Switched on request")
      create(:pair_request, subject: "Switched off request", paused_at: 1.hour.ago)

      expect(listed_subjects).to eq(["Switched on request"])
    end

    it "leaves out requests with no bookable slot in the next 14 days" do
      create(:pair_request, subject: "No weekly hours", weekly_hours: false)
      create(:pair_request, subject: "Call longer than any window", user: poster_free_on(2), duration: 180)
      create(:pair_request, subject: "Bookable", user: poster_free_on(2), duration: 60)

      expect(listed_subjects).to eq(["Bookable"])
    end

    it "leaves out the viewer's own requests" do
      create(:pair_request, subject: "Mine", user: viewer)

      expect(listed_subjects).to be_empty
    end

    it "lists the soonest bookable request first and sends its upcoming slots" do
      create(:pair_request, subject: "Thursday", user: poster_free_on(4), duration: 60)
      create(:pair_request, subject: "Tuesday", user: poster_free_on(2), duration: 60)

      expect(listed_subjects).to eq(["Tuesday", "Thursday"])

      tuesday = JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"]).dig("props", "pairRequests", 0)
      expect(tuesday["slots"].first).to eq("start_at" => "2026-11-03T18:00:00Z", "end_at" => "2026-11-03T19:00:00Z")
    end

    it "filters by requests with a bookable slot between two dates" do
      create(:pair_request, subject: "Tuesday", user: poster_free_on(2), duration: 60)
      create(:pair_request, subject: "Thursday", user: poster_free_on(4), duration: 60)

      expect(listed_subjects(q: { available_from: "2026-11-05", available_to: "2026-11-05" })).to eq(["Thursday"])
      expect(listed_subjects(q: { available_from: "2026-11-09" })).to eq(["Tuesday", "Thursday"])
      expect(listed_subjects(q: { available_to: "2026-11-03" })).to eq(["Tuesday"])
    end
  end
end
