require 'rails_helper'

RSpec.describe "Signing up", type: :request do
  around { |example| travel_to(Time.utc(2026, 11, 2, 12, 0)) { example.run } }

  def page_text
    Nokogiri::HTML(response.body).at("main").text.squish
  end

  def sign_up(date_of_birth:, email: "new@example.com")
    post user_registration_path, params: {
      user: { email:, password: "secret-password-123", password_confirmation: "secret-password-123", date_of_birth: }
    }
  end

  describe "the form" do
    it "asks for a date of birth neutrally" do
      get new_user_registration_path

      field = Nokogiri::HTML(response.body).at("input[name='user[date_of_birth]']")
      expect(field["type"]).to eq("date")
      expect(field["min"]).to be_nil
      expect(field["max"]).to be_nil
      expect(page_text).not_to match(/\d|\bover\b|older|years old|\bage\b/i)
      expect(response.body).not_to include('type="checkbox"')
    end
  end

  it "creates the account and keeps the date of birth for someone who turns 16 today" do
    expect { sign_up(date_of_birth: "2010-11-02") }.to change(User, :count).by(1)

    expect(User.last.date_of_birth).to eq(Date.new(2010, 11, 2))
  end

  it "requires a date of birth" do
    expect { sign_up(date_of_birth: "") }.not_to change(User, :count)

    expect(Nokogiri::HTML(response.body).at("form").text.squish).to include("Date of birthcan't be blank")
  end

  context "when under 16" do
    it "creates no account and stores nothing" do
      expect { sign_up(date_of_birth: "2010-11-03") }.not_to change(User, :count)
    end

    it "says why without naming the age" do
      sign_up(date_of_birth: "2010-11-03")
      follow_redirect!

      expect(page_text).to include("Sorry, we can't create an account due to an age restriction.")
      expect(page_text).not_to match(/\d/)
      expect(response.body).not_to include("user[email]")
    end

    it "blocks another attempt with a different date for about a day" do
      sign_up(date_of_birth: "2010-11-03")

      expect { sign_up(date_of_birth: "1990-01-01") }.not_to change(User, :count)
      get new_user_registration_path
      expect(response.body).to include("due to an age restriction")

      travel 25.hours

      expect { sign_up(date_of_birth: "1990-01-01") }.to change(User, :count).by(1)
    end
  end
end
