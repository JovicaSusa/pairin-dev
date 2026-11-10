require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user, date_of_birth: Date.new(1990, 6, 15)) }

  before { sign_in(user) }

  describe "PATCH /profiles/:id" do
    it "saves with country, language and level left blank, as the form sends them" do
      user.update_columns(country: nil, language: nil, level: nil)

      patch profile_path(user), params: { name: "Ada", country: "", language: "", level: "", github_url: "github.com/ada" }

      expect(response).to redirect_to(profile_path(user.id))
      expect(user.reload).to have_attributes(name: "Ada", country: nil, language: nil, level: nil, github_url: "https://github.com/ada")
    end

    it "still refuses a made-up country" do
      patch profile_path(user), params: { country: "Atlantis" }

      expect(user.reload.country).to be_nil
      expect(session[:inertia_errors]).to include(:country)
    end

    it "refuses an About over #{User::ABOUT_MAX} characters, the same cap as onboarding" do
      patch profile_path(user), params: { about: "a" * (User::ABOUT_MAX + 1) }

      expect(user.reload.about).not_to eq("a" * (User::ABOUT_MAX + 1))
      expect(session[:inertia_errors]).to include(:about)
    end

    it "still saves other fields when an older About is over the cap" do
      user.update_columns(about: "a" * (User::ABOUT_MAX + 1))

      patch profile_path(user), params: { name: "Ada" }

      expect(user.reload.name).to eq("Ada")
    end

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
