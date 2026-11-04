require 'rails_helper'

RSpec.describe "Signing up", type: :request do
  around { |example| travel_to(Time.utc(2026, 11, 2, 12, 0)) { example.run } }

  def page_text
    Nokogiri::HTML(response.body).at("main").text.squish
  end

  def sign_up(date_of_birth: nil, email: "new@example.com", **attributes)
    post user_registration_path, params: {
      user: { email:, password: "secret-password-123", password_confirmation: "secret-password-123", date_of_birth:, **attributes }.compact
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

  it "shows a form error, not the refusal, for a date in the future" do
    expect { sign_up(date_of_birth: "2030-01-01") }.not_to change(User, :count)

    expect(Nokogiri::HTML(response.body).at("form").text.squish).to include("can't be in the future")
    get new_user_registration_path
    expect(response.body).not_to include("due to an age restriction")
  end

  context "when the date is in the signer-up's timezone" do
    it "lets someone in on their birthday when it's already that day for them" do
      # 12:00 UTC on 2 Nov is 01:00 on 3 Nov in Auckland.
      expect { sign_up(date_of_birth: "2010-11-03", timezone: "Pacific/Auckland") }.to change(User, :count).by(1)
    end

    it "refuses someone whose birthday hasn't started for them yet" do
      travel_to Time.utc(2026, 11, 3, 2, 0) # Still 2 Nov in Honolulu.

      expect { sign_up(date_of_birth: "2010-11-03", timezone: "Pacific/Honolulu") }.not_to change(User, :count)
    end

    it "falls back to UTC for an unknown timezone" do
      expect { sign_up(date_of_birth: "2010-11-03", timezone: "Not/AZone") }.not_to change(User, :count)
    end
  end

  context "when under 16" do
    it "creates no account and stores nothing" do
      expect { sign_up(date_of_birth: "2010-11-03") }.not_to change(User, :count)
    end

    it "refuses a date written in another format" do
      expect { sign_up(date_of_birth: "3 Nov 2010") }.not_to change(User, :count)

      get new_user_registration_path
      expect(response.body).to include("due to an age restriction")
    end

    it "refuses a date sent as separate year, month and day fields" do
      expect {
        sign_up("date_of_birth(1i)": "2010", "date_of_birth(2i)": "11", "date_of_birth(3i)": "3")
      }.not_to change(User, :count)

      get new_user_registration_path
      expect(response.body).to include("due to an age restriction")
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

  describe "deleting an account" do
    let(:user) { create(:user) }

    before { sign_in(user) }

    it "can't be done from the app: there's no route" do
      delete "/users"

      expect(response).to have_http_status(:not_found)
      expect(User.exists?(user.id)).to be(true)
    end

    it "has no button on the account page" do
      get "/users/edit"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Cancel my account")
    end
  end

  describe "the rest of the account routes" do
    it "still shows signup" do
      get "/users/sign_up"

      expect(response).to have_http_status(:ok)
    end

    it "still lets someone change their password" do
      user = create(:user, password: "Password33*")
      sign_in(user)

      put "/users", params: { user: { password: "Different44*", password_confirmation: "Different44*", current_password: "Password33*" } }

      expect(user.reload).to be_valid_password("Different44*")
    end
  end
end
