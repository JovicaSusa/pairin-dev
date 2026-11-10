require "rails_helper"

# Partners see the name, so an account without one gives it once, before
# anything else (#262).
RSpec.describe "Asking for a name", type: :request do
  let(:user) { create(:user, name: nil) }

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  before { sign_in(user) }

  it "stops an account without a name until it gives one, then returns to the page it asked for" do
    create(:pair_request, user:)

    get partners_path
    expect(response).to redirect_to(name_path)

    get name_path
    expect(response).to have_http_status(:ok)

    patch name_path, params: { name: "  Maya  " }
    expect(user.reload.name).to eq("Maya")
    expect(response).to redirect_to(partners_path)

    get partners_path
    expect(response).to have_http_status(:ok)
  end

  it "won't take a blank or overlong name" do
    patch name_path, params: { name: "   " }
    expect(response).to redirect_to(name_path)
    expect(session[:inertia_errors]).to include(name: "Enter a name")

    patch name_path
    expect(session[:inertia_errors]).to include(name: "Enter a name")

    patch name_path, params: { name: "x" * 61 }
    expect(session[:inertia_errors]).to include(name: "Keep it to 60 characters")
    expect(user.reload.name).to be_nil
  end

  it "sends someone who still needs onboarding on to it" do
    patch name_path, params: { name: "Maya" }

    expect(response).to redirect_to(onboarding_path)
  end

  it "asks for the date of birth first" do
    user.update_columns(date_of_birth: nil)

    get name_path

    expect(response).to redirect_to(date_of_birth_path)
  end

  it "doesn't stop onboarding, which asks for the name itself" do
    get onboarding_path

    expect(response).to have_http_status(:ok)
  end

  it "leaves the page once there's a name" do
    user.update_columns(name: "Maya")

    get name_path

    expect(response).to redirect_to(pair_requests_path)
  end
end
