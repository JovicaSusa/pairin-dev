require "rails_helper"

RSpec.describe "Log out", type: :request do
  before { sign_in(create(:user)) }

  it "tells the app to leave with a full page load, because the home page isn't part of it" do
    delete destroy_user_session_path, headers: { "X-Inertia" => "true" }

    expect(response).to have_http_status(:conflict)
    expect(response.headers["X-Inertia-Location"]).to eq(root_path)
  end

  it "still redirects a normal request" do
    delete destroy_user_session_path

    expect(response).to redirect_to(root_path)
  end
end
