require "rails_helper"

RSpec.describe "/pair_requests/:pair_request_id/offers/new", type: :view do
  let!(:pair_request) { create(:pair_request) }
  let!(:past_period) { create(:period, start_at: 1.minute.from_now, periodable: pair_request) }
  let!(:future_period) { create(:period, start_at: 3.minutes.from_now, periodable: pair_request) }

  before do
    user = create(:user)

    assign(:pair_request, pair_request)
    assign(:offer, pair_request.offers.build(offerer: user))
  end

  it "renders only future periods" do
    travel 2.minutes do
      render template: "/pair_requests/offers/new"
    end

    expect(rendered).to include(future_period.start_at.to_fs(:short))
    expect(rendered).not_to include(past_period.start_at.to_fs(:short))
  end
end
