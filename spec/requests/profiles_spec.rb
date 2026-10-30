require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user, date_of_birth: Date.new(1990, 6, 15)) }

  before { sign_in(user) }

  describe "PATCH /profiles/:id" do
    it "updates the profile but never the date of birth" do
      patch profile_path(user), params: { name: "Ada", date_of_birth: "2015-01-01" }

      expect(user.reload.name).to eq("Ada")
      expect(user.date_of_birth).to eq(Date.new(1990, 6, 15))
    end
  end
end
