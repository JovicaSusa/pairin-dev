require "rails_helper"

RSpec.describe "Date of birth step", type: :request do
  let(:user) { create(:user).tap { |u| u.update_columns(date_of_birth: nil) } }

  before { sign_in(user) }

  it "sends an account with no date of birth to the step, from any page" do
    [pair_requests_path, sessions_path, profile_path(user), availability_path].each do |path|
      sign_in(user)
      get path

      expect(response).to redirect_to(date_of_birth_path)
    end
  end

  it "shows the step, without mentioning an age" do
    get date_of_birth_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to match(/\b16\b|minimum age/i)
  end

  it "saves an adult's answer and lets them through" do
    patch date_of_birth_path, params: { date_of_birth: "1990-06-15" }

    expect(response).to redirect_to(onboarding_path)
    expect(user.reload.date_of_birth).to eq(Date.new(1990, 6, 15))

    get pair_requests_path
    expect(response).to have_http_status(:ok)
  end

  it "only asks once" do
    patch date_of_birth_path, params: { date_of_birth: "1990-06-15" }

    get date_of_birth_path
    expect(response).to redirect_to(pair_requests_path)

    patch date_of_birth_path, params: { date_of_birth: "2020-01-01" }
    expect(user.reload.date_of_birth).to eq(Date.new(1990, 6, 15))
    expect(user).not_to be_suspended
  end

  it "saves it even when the rest of an older profile wouldn't pass validation" do
    user.update_columns(language: "not-a-language")

    patch date_of_birth_path, params: { date_of_birth: "1990-06-15" }

    expect(user.reload.date_of_birth).to eq(Date.new(1990, 6, 15))
  end

  [["blank", ""], ["not a date", "soon"], ["in the future", "2999-01-01"]].each do |name, value|
    it "refuses an answer that's #{name}" do
      patch date_of_birth_path, params: { date_of_birth: value }

      expect(response).to redirect_to(date_of_birth_path)
      expect(session[:inertia_errors]).to include(:date_of_birth)
      expect(user.reload.date_of_birth).to be_nil
      expect(user).not_to be_suspended
    end
  end

  describe "an under-16 answer" do
    let!(:search) { create(:pair_request, user:) }

    before { patch date_of_birth_path, params: { date_of_birth: 15.years.ago.to_date.iso8601 } }

    it "suspends the account, signs them out and sends them to the message" do
      expect(user.reload).to be_suspended
      expect(response).to have_http_status(:conflict)
      expect(response.headers["X-Inertia-Location"]).to include(account_suspended_path)

      get pair_requests_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "doesn't keep the date they gave" do
      expect(user.reload.date_of_birth).to be_nil
    end

    it "switches their searches off" do
      expect(search.reload).to be_paused
    end

    it "shows the message" do
      get account_suspended_path

      expect(response.body).to include("due to an age restriction")
      expect(response.body).to include("14 days")
    end

    it "stops them signing back in" do
      post user_session_path, params: { user: { email: user.email, password: user.password } }

      get pair_requests_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "ends a session already open elsewhere" do
      sign_in(user.reload)

      get pair_requests_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  it "counts turning 16 today as old enough" do
    patch date_of_birth_path, params: { date_of_birth: 16.years.ago.to_date.iso8601 }

    expect(user.reload).not_to be_suspended
    expect(user.date_of_birth).to be_present
  end
end
