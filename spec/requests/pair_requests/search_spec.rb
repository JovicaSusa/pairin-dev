require 'rails_helper'

RSpec.describe "PairRequests", type: :request do
  describe "GET /search" do
    it "performs expected search" do
      get "/pair_requests/search",
        params: {
          q: {
            tags_name_eq: "Ruby",
            q_duration_eq: 45,
            q_user_level_eq: "beginner",
            q_user_language_eq: "SR",
            q_periods_start_at_gteq: 5.days.from_now,
            q_periods_end_at_lteq: 6.days.from_now,
          }
        }

      # TODO: Add exceptions
    end
  end
end
