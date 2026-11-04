require "rails_helper"

RSpec.describe "Shareable partner search links", type: :request do
  let(:poster) { create(:user, name: "Maya Jones", email: "maya@example.com", level: "competent", profession: "Teacher", github_url: "https://github.com/maya") }
  let(:search) { create(:pair_request, user: poster, subject: "Python buddy", description: "Work through a course", commitment: "open_ended") }
  let(:token) { search.share_token }

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  describe "the token" do
    it "is random and different for each search, and not based on the ID" do
      other = create(:pair_request)

      expect(token.length).to eq(24)
      expect(token).not_to eq(other.share_token)
      expect(token).not_to include(search.id.to_s * 3)
    end
  end

  describe "the page, with no account" do
    it "shows the search, with the poster's first name and level" do
      create(:tagging, taggable: search, tag: create(:tag, name: "python"))

      get public_search_path(token:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Python buddy", "Work through a course", "Open-ended", "python", "Maya", "Competent", "Apply to Maya")
    end

    it "shows nothing else about the poster" do
      get public_search_path(token:)

      expect(response.body).not_to include("Jones", "maya@example.com", "Teacher", "github.com/maya")
    end

    it "stays out of search engines and loads no analytics" do
      get public_search_path(token:)

      expect(response.headers["X-Robots-Tag"]).to include("noindex")
      expect(response.body).to include('<meta name="robots" content="noindex, nofollow">')
      expect(response.body).not_to include("posthog")
    end

    it "escapes what the poster wrote" do
      search.update!(description: "<script>alert(1)</script>")

      get public_search_path(token:)

      expect(response.body).not_to include("<script>alert(1)")
    end

    it "uses a fallback name when the poster has none" do
      poster.update_columns(name: nil)

      get public_search_path(token:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Apply to A")
    end

    it "shows a not-found page for a bad token, and not for a search ID" do
      get public_search_path(token: "nope")
      expect(response).to have_http_status(:not_found)

      get public_search_path(token: search.id)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "a search that's closed" do
    it "says so when it's Off, with no Apply" do
      search.switch_off!

      get public_search_path(token:)

      expect(response.body).to include("no longer open", pair_requests_path)
      expect(response.body).not_to include("Apply to")
    end

    it "says so when it has found a partner" do
      offer = create(:offer, pair_request: search)
      offer.post_message(poster, "Hi")
      offer.propose_partnership!(by: offer.offerer)
      offer.accept_proposal!(by: poster)

      get public_search_path(token:)

      expect(response.body).to include("no longer open")
    end
  end

  describe "an under-18 poster" do
    let(:poster) { create(:user, name: "Mia", date_of_birth: 17.years.ago.to_date) }

    it "has no page, and can't start an application from it" do
      get public_search_path(token:)
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("Python buddy")

      get public_search_apply_path(token:)
      expect(response).to have_http_status(:not_found)
    end

    it "gets no link on their searches" do
      search
      sign_in(poster)

      get users_pair_requests_path

      expect(props["pairRequests"].first["share_path"]).to be_nil
    end
  end

  describe "the poster's own view" do
    before do
      search
      sign_in(poster)
    end

    it "gets the link while it's open" do
      get users_pair_requests_path

      expect(props["pairRequests"].first["share_path"]).to eq("/s/#{token}")
    end

    it "doesn't get it once it's Off" do
      search.switch_off!

      get users_pair_requests_path

      expect(props["pairRequests"].first["share_path"]).to be_nil
    end

    it "sees no Apply on their own page" do
      get public_search_path(token:)

      expect(response.body).to include("how your partner search looks")
      expect(response.body).not_to include("Apply to")
    end
  end

  describe "applying when signed in" do
    it "goes straight to the form" do
      sign_in(create(:user))

      get public_search_apply_path(token:)

      expect(response).to redirect_to(new_pair_request_offer_path(search, via: "share"))
    end

    it "keeps the age-group rule" do
      sign_in(create(:user, date_of_birth: 17.years.ago.to_date))

      get public_search_apply_path(token:)
      follow_redirect!

      expect(response).to redirect_to(pair_requests_path)
      expect(flash[:alert]).to include("switched off")
    end

    it "keeps the block rule" do
      user = create(:user)
      poster.block!(user)
      sign_in(user)

      get public_search_apply_path(token:)
      follow_redirect!

      expect(response).to redirect_to(pair_requests_path)
      expect(flash[:alert]).to include("switched off")
    end

    it "marks the application as coming through the link" do
      sign_in(create(:user))

      post pair_request_offers_path(search), params: { offer: { message: "Hi", goal: "A goal", how_often: "once_a_week", how_long: "few_weeks", via_share_link: true } }

      expect(Offer.last).to be_via_share_link
    end
  end

  describe "applying as a non-member" do
    let(:signup) { { user: { email: "new@example.com", password: "Password33*", password_confirmation: "Password33*", date_of_birth: "1990-06-15" } } }

    def sign_in_as_new_person
      post user_session_path, params: { user: { email: "new@example.com", password: "Password33*" } }
    end

    before { get public_search_apply_path(token:) }

    it "goes to signup, and the account remembers the search" do
      expect(response).to redirect_to(new_user_registration_path)

      post user_registration_path, params: signup

      expect(User.find_by!(email: "new@example.com").signup_pair_request).to eq(search)
    end

    it "returns to the form in the same browser, skipping onboarding" do
      post user_registration_path, params: signup
      User.find_by!(email: "new@example.com").confirm

      sign_in_as_new_person

      expect(response).to redirect_to(new_pair_request_offer_path(search, via: "share"))
    end

    it "returns to the form when confirming on another device" do
      post user_registration_path, params: signup
      User.find_by!(email: "new@example.com").confirm

      reset!
      sign_in_as_new_person

      expect(response).to redirect_to(new_pair_request_offer_path(search, via: "share"))
    end

    it "only does that the first time" do
      post user_registration_path, params: signup
      User.find_by!(email: "new@example.com").confirm
      reset!
      sign_in_as_new_person
      delete destroy_user_session_path

      sign_in_as_new_person

      expect(response).to redirect_to(onboarding_path)
    end

    it "goes to onboarding when the search has closed by then" do
      post user_registration_path, params: signup
      User.find_by!(email: "new@example.com").confirm
      search.switch_off!
      reset!

      sign_in_as_new_person

      expect(response).to redirect_to(onboarding_path)
    end

    it "doesn't let the form choose the search" do
      other = create(:pair_request)
      post user_registration_path, params: { user: signup[:user].merge(signup_pair_request_id: other.id) }

      expect(User.find_by!(email: "new@example.com").signup_pair_request).to eq(search)
    end

    it "returns an existing member who signs in instead" do
      member = create(:user, password: "Password33*")

      post user_session_path, params: { user: { email: member.email, password: "Password33*" } }

      expect(response).to redirect_to(new_pair_request_offer_path(search, via: "share"))
    end

    it "doesn't tag a later signup in the same browser" do
      post user_registration_path, params: signup

      post user_registration_path, params: { user: signup[:user].merge(email: "second@example.com") }

      expect(User.find_by(email: "second@example.com")&.signup_pair_request).to be_nil
    end
  end

  it "survives the poster's account being deleted" do
    get public_search_apply_path(token:)
    post user_registration_path, params: { user: { email: "new@example.com", password: "Password33*", password_confirmation: "Password33*", date_of_birth: "1990-06-15" } }

    poster.destroy!

    expect(User.find_by!(email: "new@example.com").signup_pair_request).to be_nil
    get public_search_path(token:)
    expect(response).to have_http_status(:not_found)
  end

  it "counts signups and applications in the funnel" do
    freeze_time do
      user = create(:user, signup_pair_request: search)
      create(:offer, pair_request: search, offerer: user, via_share_link: true)
      create(:offer, pair_request: search)

      funnel = Stats::Funnel.new(since: 1.hour.ago)

      expect(funnel.signups_via_share_link).to eq(1)
      expect(funnel.applications_via_share_link).to eq(1)
      expect(funnel.report).to include("Signups via shared link", "Applications via shared link")
    end
  end

  it "states this on the legal pages" do
    get privacy_path
    expect(response.body).to include("Anyone with that link can read the search")

    get terms_path
    expect(response.body).to include("Anyone with the link to your partner")
  end
end
