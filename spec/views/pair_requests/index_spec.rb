require "rails_helper"

RSpec.describe "/pair_requests/index", type: :view do
  before do
    assign(:q, PairRequest.ransack({}))
    assign(:pair_requests, [])
    assign(:pagy, Pagy.new(count: 1))
  end

  describe "/pair_requests/index" do
    it "renders search form" do
    render

    expect(rendered).to include("q_tags_name_eq")
    expect(rendered).to include("q_duration_eq")
    expect(rendered).to include("q_user_level_eq")
    expect(rendered).to include("q_user_language_eq")
    expect(rendered).to include("q_periods_start_at_gteq")
    expect(rendered).to include("q_periods_end_at_lteq")
    end
  end
end
