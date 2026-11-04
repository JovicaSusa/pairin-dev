require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user, date_of_birth: Date.new(1990, 6, 15)) }

  before { sign_in(user) }

  describe "PATCH /profiles/:id" do
    it "saves a GitHub link" do
      patch profile_path(user), params: { github_url: "https://github.com/ada" }

      expect(user.reload.github_url).to eq("https://github.com/ada")
    end

    it "refuses a link that isn't to GitHub" do
      patch profile_path(user), params: { github_url: "https://evil.example/ada" }

      expect(user.reload.github_url).to be_nil
      expect(session[:inertia_errors]).to include(:github_url)
    end

    it "updates the profile but never the date of birth" do
      patch profile_path(user), params: { name: "Ada", date_of_birth: "2015-01-01" }

      expect(user.reload.name).to eq("Ada")
      expect(user.date_of_birth).to eq(Date.new(1990, 6, 15))
    end
  end
end
