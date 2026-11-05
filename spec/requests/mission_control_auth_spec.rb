require "rails_helper"

RSpec.describe "Jobs dashboard sign-in", type: :request do
  def stub_login(name:, password:)
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:mission_control, :name).and_return(name)
    allow(Rails.application.credentials).to receive(:dig).with(:mission_control, :password).and_return(password)
  end

  def basic_auth(name, password)
    { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(name, password) }
  end

  before { stub_login(name: "admin", password: "secret") }

  it "asks for a login, rather than failing, when none is given" do
    get "/jobs"

    expect(response).to have_http_status(:unauthorized)
    expect(response.headers["WWW-Authenticate"]).to include("Basic")
  end

  it "refuses the wrong password" do
    get "/jobs", headers: basic_auth("admin", "wrong")

    expect(response).to have_http_status(:unauthorized)
  end

  it "stays closed when no login is configured, even for an empty one" do
    stub_login(name: nil, password: nil)

    get "/jobs", headers: basic_auth("", "")

    expect(response).to have_http_status(:forbidden)
  end
end

# The dashboard itself can't render on the test queue adapter, so this one checks
# the login with a stand-in page.
RSpec.describe MissionControlAuthController, type: :controller do
  controller do
    def index
      head :ok
    end
  end

  it "lets the right login through" do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:mission_control, :name).and_return("admin")
    allow(Rails.application.credentials).to receive(:dig).with(:mission_control, :password).and_return("secret")
    request.headers["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret")

    get :index

    expect(response).to have_http_status(:ok)
  end
end
