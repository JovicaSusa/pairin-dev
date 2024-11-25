require "rails_helper"

RSpec.describe "/users/pair_requests/index", type: :view do
  before do
    assign(:pair_requests, [pair_request])
    sign_in(create(:user))
  end

  context "when pair request has accepted offer" do
    let(:pair_request) { create(:pair_request) }

    before do
      create(:offer, :accepted, pair_request:)
      create(:session, sessionable: pair_request)
    end

    it "shows set call link form" do
      render

      expect(rendered).to include("Add")
    end
  end

  context "when pair request doesn't have accepted offer" do
    let(:pair_request) { create(:pair_request) }

    it "doesn't show set call link form" do
      render

      expect(rendered).not_to include("Add")
    end
  end
end
