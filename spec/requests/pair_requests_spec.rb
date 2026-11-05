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

    it "lists requests that are on and leaves out requests that are off" do
      create(:pair_request, subject: "Switched on request")
      create(:pair_request, subject: "Switched off request", paused_at: 1.hour.ago)

      expect(listed_subjects).to eq(["Switched on request"])
    end

    it "lists a poster with no weekly hours" do
      create(:pair_request, subject: "No weekly hours")

      expect(listed_subjects).to eq(["No weekly hours"])
    end

    it "filters by commitment and sends its label" do
      create(:pair_request, subject: "Short", commitment: "few_weeks")
      create(:pair_request, subject: "Long", commitment: "open_ended")

      expect(listed_subjects(q: { commitment_eq: "open_ended" })).to eq(["Long"])

      long = JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"]).dig("props", "pairRequests", 0)
      expect(long["commitment_label"]).to eq("Open-ended")
    end

    it "leaves out the viewer's own requests" do
      create(:pair_request, subject: "Mine", user: viewer)

      expect(listed_subjects).to be_empty
    end

    it "lists the newest first, with no slots" do
      create(:pair_request, subject: "Older", created_at: 2.days.ago)
      create(:pair_request, subject: "Newer", created_at: 1.day.ago)

      expect(listed_subjects).to eq(["Newer", "Older"])

      newer = JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"]).dig("props", "pairRequests", 0)
      expect(newer).not_to include("slots")
    end
  end
end
