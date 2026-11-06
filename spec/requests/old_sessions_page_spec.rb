require "rails_helper"

RSpec.describe "The old sessions page", type: :request do
  it "is gone" do
    sign_in create(:user)

    get "/sessions"

    expect(response).to have_http_status(:not_found)
  end
end
