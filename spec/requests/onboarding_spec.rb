require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let(:user) { create(:user, level: nil, password: "Password33*") }

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  let(:answers) do
    {
      topics: ["Python", "Web scraping"],
      level: "novice",
      goal: "Finish a course",
      commitment: "open_ended",
      timezone: "Europe/Berlin",
      windows: [{ weekday: 2, start_minute: 1080, end_minute: 1200 }]
    }
  end

  describe "after signing in" do
    def sign_in_through_the_form
      post user_session_path, params: { user: { email: user.email, password: "Password33*" } }
    end

    it "sends someone with no search to onboarding" do
      sign_in_through_the_form

      expect(response).to redirect_to(onboarding_path)
    end

    it "sends someone with a search to the list" do
      create(:pair_request, user:)

      sign_in_through_the_form

      expect(response).to redirect_to(pair_requests_path)
    end

    it "doesn't force it again once skipped" do
      user.update_columns(onboarding_skipped_at: 1.day.ago)

      sign_in_through_the_form

      expect(response).to redirect_to(pair_requests_path)
    end

    it "still returns someone to a page they asked for first" do
      user.update_columns(level: "novice")
      offer = create(:offer, offerer: user)
      get conversation_path(offer)

      sign_in_through_the_form

      expect(response).to redirect_to(conversation_path(offer))
    end
  end

  describe "the date-of-birth step" do
    it "comes first, then leads to onboarding" do
      user.update_columns(date_of_birth: nil)
      sign_in(user)

      get onboarding_path
      expect(response).to redirect_to(date_of_birth_path)

      patch date_of_birth_path, params: { date_of_birth: "1990-06-15" }
      expect(response).to redirect_to(onboarding_path)
    end
  end

  describe "the page" do
    before { sign_in(user) }

    it "has no session length, and offers tags, levels and commitments" do
      create(:tag, name: "ruby")

      get onboarding_path

      expect(props["tags"]).to include("ruby")
      expect(props["commitments"].map { |c| c["value"] }).to include("one_to_three_months")
      expect(props["levels"]).to include("novice")
      expect(response.body).not_to match(/duration|session length|intro/i)
    end

    it "sends someone who already has a search to their searches" do
      create(:pair_request, user:)

      get onboarding_path

      expect(response).to redirect_to(users_pair_requests_path)
    end
  end

  describe "finishing" do
    before { sign_in(user) }

    def finish(params = answers) = post(onboarding_path, params:, as: :json)

    it "saves the profile, the hours and an On search, then lands on the user's searches" do
      finish

      expect(response).to redirect_to(users_pair_requests_path)
      expect(user.reload).to have_attributes(level: "novice", timezone: "Europe/Berlin")
      expect(user.availability_windows.pluck(:weekday, :start_minute, :end_minute)).to eq([[2, 1080, 1200]])

      search = user.pair_requests.sole
      expect(search).not_to be_paused
      expect(search).to have_attributes(subject: "Learning partner for Python and Web scraping", description: "Finish a course", commitment: "open_ended")
      expect(search.tags.pluck(:name)).to contain_exactly("python", "web scraping")
    end

    it "can skip the goal, the commitment and the hours" do
      finish(topics: ["Python"], level: "novice")

      search = user.pair_requests.sole
      expect(search.commitment).to eq("one_to_three_months")
      expect(search.description).to include("Python")
      expect(user.availability_windows).to be_empty
    end

    it "needs a topic and a level, and saves nothing without them" do
      expect { finish(answers.merge(topics: [])) }.not_to change(PairRequest, :count)
      expect(session[:inertia_errors]).to include(:topics)

      expect { finish(answers.merge(level: "")) }.not_to change(PairRequest, :count)
      expect(session[:inertia_errors]).to include(:level)

      expect { finish(answers.merge(level: "wizard")) }.not_to change(PairRequest, :count)
      expect(user.reload.level).to be_nil
    end

    it "isn't blocked by hours they saved earlier" do
      create(:availability_window, user:, weekday: 2, start_minute: 1080, end_minute: 1200)

      finish(answers.merge(windows: [
        { weekday: 2, start_minute: 1140, end_minute: 1260 },
        { weekday: 3, start_minute: 600, end_minute: 660 }
      ]))

      expect(user.pair_requests.count).to eq(1)
      expect(user.availability_windows.chronological.pluck(:weekday, :start_minute, :end_minute)).to eq([[2, 1080, 1200], [3, 600, 660]])
    end

    it "posts one search when submitted twice at once" do
      params = ActionController::Parameters.new(answers).permit(:level, :goal, :commitment, :timezone, topics: [], windows: [:weekday, :start_minute, :end_minute])

      first = Onboarding::Finish.call(user, params)
      second = Onboarding::Finish.call(user, params)

      expect(second).to be_success
      expect(second.pair_request).to eq(first.pair_request)
      expect(user.pair_requests.count).to eq(1)
    end

    it "tries again when someone else creates the same new topic at that moment" do
      calls = 0
      allow(Tag).to receive(:find_or_create_by!).and_wrap_original do |original, **args|
        calls += 1
        raise ActiveRecord::RecordNotUnique, "duplicate" if calls == 1

        original.call(**args)
      end

      finish(answers.merge(topics: ["Brand new"]))

      expect(response).to redirect_to(users_pair_requests_path)
      expect(user.pair_requests.sole.tags.pluck(:name)).to eq(["brand new"])
    end

    it "saves nothing at all when something's wrong" do
      finish(answers.merge(windows: [{ weekday: 2, start_minute: 1200, end_minute: 1080 }]))

      expect(response).to redirect_to(onboarding_path)
      expect(user.reload.level).to be_nil
      expect(user.pair_requests).to be_empty
      expect(user.availability_windows).to be_empty
    end

    it "refuses an unknown commitment" do
      expect { finish(answers.merge(commitment: "forever")) }.not_to change(PairRequest, :count)

      expect(user.reload.level).to be_nil
    end

    it "keeps the current timezone when given an unknown one" do
      user.update_columns(timezone: "Asia/Tokyo")

      finish(answers.merge(timezone: "Mars/Olympus"))

      expect(user.reload.timezone).to eq("Asia/Tokyo")
    end

    it "treats the same topic twice as one" do
      finish(answers.merge(topics: ["Python", "python ", " PYTHON"]))

      expect(user.pair_requests.sole.tags.pluck(:name)).to eq(["python"])
    end

    it "works on an older profile that wouldn't pass validation" do
      user.update_columns(language: "not-a-language")

      finish

      expect(user.reload.level).to eq("novice")
    end
  end

  describe "landing on your searches" do
    let(:python) { create(:tag, name: "python") }

    before { sign_in(user) }

    def matches
      get users_pair_requests_path
      props["matches"].map { |match| match["subject"] }
    end

    def search_tagged(subject, tag = python, **user_attrs)
      create(:pair_request, subject:, user: create(:user, **user_attrs)).tap { |search| create(:tagging, taggable: search, tag:) }
    end

    before { create(:pair_request, user:).tap { |search| create(:tagging, taggable: search, tag: python) } }

    it "shows open searches with the same tags, in the same age group" do
      search_tagged("Match")
      search_tagged("Other topic", create(:tag, name: "rust"))
      search_tagged("Off").update!(paused_at: 1.hour.ago)
      search_tagged("A minor's", date_of_birth: 17.years.ago.to_date)

      expect(matches).to eq(["Match"])
    end

    it "leaves out searches they've already applied to" do
      user.update_columns(level: "novice")
      create(:offer, pair_request: search_tagged("Applied"), offerer: user)

      expect(matches).to be_empty
    end

    it "leaves out someone they've blocked" do
      blocked = search_tagged("Blocked")
      user.block!(blocked.user)

      expect(matches).to be_empty
    end
  end

  it "has no matches to show before a search exists" do
    sign_in(user)

    get users_pair_requests_path

    expect(props["matches"]).to eq([])
  end

  describe "skipping" do
    before { sign_in(user) }

    it "lands on the list with a banner, until a search is posted" do
      post skip_onboarding_path

      expect(response).to redirect_to(pair_requests_path)
      expect(user.reload.onboarding_skipped_at).to be_present

      get pair_requests_path
      expect(props["finishSetup"]).to be(true)

      get onboarding_path
      expect(response).to have_http_status(:ok)

      create(:pair_request, user:)
      get pair_requests_path
      expect(props["finishSetup"]).to be(false)
    end
  end

  it "needs sign-in" do
    get onboarding_path

    expect(response).to redirect_to(new_user_session_path)
  end
end
