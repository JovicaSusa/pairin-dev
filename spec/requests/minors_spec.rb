require "rails_helper"

RSpec.describe "Protections for under-18s", type: :request do
  let(:minor) { create(:user, name: "Mia", date_of_birth: 17.years.ago.to_date, level: "novice", profession: "Student", github_url: "https://github.com/mia") }
  let(:other_minor) { create(:user, name: "Ben", date_of_birth: 16.years.ago.to_date) }
  let(:adult) { create(:user, name: "Ada", date_of_birth: 30.years.ago.to_date, level: "expert", profession: "Engineer") }

  let!(:minor_search) { create(:pair_request, subject: "Minor search", user: other_minor) }
  let!(:adult_search) { create(:pair_request, subject: "Adult search", user: adult) }

  def props
    JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"])["props"]
  end

  def listed_subjects
    get pair_requests_path
    props["pairRequests"].map { |request| request["subject"] }
  end

  let(:answers) { { message: "Hi", goal: "A goal", how_often: "once_a_week", how_long: "few_weeks" } }

  describe "who sees whom" do
    it "shows an under-18 only under-18 searches" do
      sign_in(minor)

      expect(listed_subjects).to eq(["Minor search"])
    end

    it "shows an adult only adult searches" do
      sign_in(create(:user, date_of_birth: 40.years.ago.to_date))

      expect(listed_subjects).to eq(["Adult search"])
    end

    it "treats turning 18 today as adult" do
      sign_in(create(:user, date_of_birth: 18.years.ago.to_date))

      expect(listed_subjects).to eq(["Adult search"])
    end

    it "treats someone a day short of 18 as under-18" do
      sign_in(create(:user, date_of_birth: 18.years.ago.to_date + 1))

      expect(listed_subjects).to eq(["Minor search"])
    end

    it "hides a search whose poster hasn't given a date of birth" do
      unknown = create(:user)
      unknown.update_columns(date_of_birth: nil)
      create(:pair_request, subject: "Unknown", user: unknown)
      sign_in(create(:user))

      expect(listed_subjects).to eq(["Adult search"])
    end
  end

  describe "someone with no date of birth" do
    it "sees nobody's searches" do
      unknown = create(:user)
      unknown.update_columns(date_of_birth: nil)
      sign_in(unknown)

      expect(listed_subjects).to be_empty
    end
  end

  describe "turning 18 in the middle of a chat" do
    let(:turning) { create(:user, name: "Tess", date_of_birth: 18.years.ago.to_date + 2) }
    let!(:offer) { create(:offer, pair_request: minor_search, offerer: turning, message: "Hi Ben") }

    before do
      offer.post_message(other_minor, "Hello")
      travel 3.days
    end

    it "ends the chat for both, so neither can write" do
      expect(turning.reload).to be_adult
      expect(other_minor.reload).to be_minor
      expect(offer.reload).to be_ended

      sign_in(other_minor)
      expect { post conversation_messages_path(offer), params: { message: { body: "Still there?" } } }.not_to change(Message, :count)

      sign_in(turning)
      expect { post conversation_messages_path(offer), params: { message: { body: "Yes" } } }.not_to change(Message, :count)
    end

    it "shows it as ended, keeps it readable and sends no unread email" do
      sign_in(other_minor)
      get conversation_path(offer)

      expect(props["conversation"]).to include("status" => "Ended", "can_send" => false, "ended_by_viewer" => false)
      expect(props.dig("conversation", "messages").size).to eq(2)

      expect { UnreadMessagesEmailJob.perform_now(offer, turning) }
        .not_to have_enqueued_mail(OfferMailer, :unread_messages_email)
    end

    it "leaves a chat between two adults alone" do
      adults = create(:offer, pair_request: adult_search)

      expect(adults).not_to be_ended
    end
  end

  describe "applying" do
    it "stops an under-18 applying to an adult, with the same answer as a switched-off search" do
      sign_in(minor)

      expect { post pair_request_offers_path(adult_search), params: { offer: answers } }.not_to change(Offer, :count)

      expect(flash[:alert]).to eq("This partner search is switched off and isn't taking applications right now.")
    end

    it "stops an adult applying to an under-18" do
      sign_in(adult)

      expect { post pair_request_offers_path(minor_search), params: { offer: answers } }.not_to change(Offer, :count)
    end

    it "lets under-18s apply to each other" do
      sign_in(minor)

      expect { post pair_request_offers_path(minor_search), params: { offer: answers } }.to change(Offer, :count).by(1)
    end

    it "can't create a chat across age groups even without the controller" do
      offer = build(:offer, offerer: minor, pair_request: adult_search)

      expect(offer).not_to be_valid
      expect(offer.errors[:base]).to be_present
    end
  end

  describe "suggestions" do
    it "stay within the age group" do
      dead = create(:offer, offerer: minor, pair_request: create(:pair_request, user: create(:user, date_of_birth: 17.years.ago.to_date)))

      expect(PairRequests::Suggestions.call(dead)).to eq([minor_search])
    end
  end

  describe "what others see of an under-18" do
    let!(:search) { create(:pair_request, subject: "Mia's search", user: minor) }
    let!(:offer) { create(:offer, pair_request: minor_search, offerer: minor, message: "Hi Ben") }

    before { sign_in(other_minor) }

    it "shows only their name on a search card" do
      get pair_requests_path

      user = props["pairRequests"].find { |r| r["subject"] == "Mia's search" }["user"]
      expect(user).to include("name" => "Mia", "image_url" => nil, "profession" => nil, "level" => nil, "github_url" => nil)
    end

    it "shows only their name in a conversation" do
      get conversation_path(offer)

      expect(props.dig("conversation", "other")).to include("name" => "Mia", "image_url" => nil, "level" => nil, "github_url" => nil)
      expect(response.body).not_to include("github.com/mia")
      expect(response.body).not_to include("Student")
    end

    it "shows only their name in the applications list" do
      get pair_request_offers_path(minor_search)

      expect(props["offers"].first["offerer"]).to include("name" => "Mia", "image_url" => nil, "github_url" => nil, "level" => nil)
    end

    it "keeps it out of the application email" do
      body = OfferMailer.with(offer:).offer_received_email.body.encoded

      expect(body).to include("Mia")
      expect(body).not_to include("github.com/mia")
      expect(body).not_to include("Novice")
    end

    [
      { user_level_eq: "expert" },
      { user_level_cont: "exp" },
      { user_level_start: "exp" },
      { user_level_not_eq: "novice" },
      { user_language_cont: "EN" },
      { user_level_or_user_language_cont: "exp" },
      { c: { "0" => { a: { "0" => { name: "user_level" } }, p: "eq", v: { "0" => { value: "expert" } } } } },
      { g: { "0" => { user_level_eq: "expert" } } }
    ].each do |filter|
      it "ignores #{filter.keys.first}, which would reveal a hidden profile field" do
        sign_in(minor)
        create(:pair_request, subject: "Expert minor", user: create(:user, date_of_birth: 17.years.ago.to_date, level: "expert"))

        get pair_requests_path, params: { q: filter }

        expect(props["pairRequests"].map { |r| r["subject"] }).to include("Minor search", "Expert minor")
      end
    end

    it "ignores a sort on the poster, which would order by a hidden field" do
      sign_in(minor)
      expert = create(:pair_request, subject: "Expert minor", user: create(:user, date_of_birth: 17.years.ago.to_date, level: "expert"), created_at: 1.year.ago)

      get pair_requests_path, params: { q: { s: "user_level asc" } }

      expect(props["pairRequests"].last["id"]).to eq(expert.id)
    end

    it "still lets them filter by tag and commitment" do
      sign_in(minor)
      create(:pair_request, subject: "Long minor", commitment: "open_ended", user: create(:user, date_of_birth: 17.years.ago.to_date))

      get pair_requests_path, params: { q: { commitment_eq: "open_ended" } }

      expect(props["pairRequests"].map { |r| r["subject"] }).to eq(["Long minor"])
    end

    it "still lets an adult filter by level" do
      sign_in(create(:user))
      create(:pair_request, subject: "Novice adult", user: create(:user, level: "novice"))

      get pair_requests_path, params: { q: { user_level_eq: "expert" } }

      expect(props["pairRequests"].map { |r| r["subject"] }).to eq(["Adult search"])
    end

    it "still shows them their own profile in full" do
      sign_in(minor)

      get profile_path(minor)

      expect(props["user"]).to include("profession" => "Student", "level" => "novice")
    end
  end

  it "shows an adult's profile as usual" do
    sign_in(create(:user))

    get pair_requests_path

    expect(props["pairRequests"].first["user"]).to include("name" => "Ada", "profession" => "Engineer", "level" => "Expert")
  end

  describe "analytics" do
    it "doesn't load PostHog for an under-18, in the app or on marketing pages" do
      sign_in(minor)

      get pair_requests_path
      expect(response.body).not_to include("posthog.init")

      get root_path
      expect(response.body).not_to include("posthog.init")

      get privacy_path
      expect(response.body).not_to include("posthog.init")
    end

    it "still loads it for an adult and for signed-out visitors" do
      get root_path
      expect(response.body).to include("posthog.init")

      sign_in(adult)
      get pair_requests_path
      expect(response.body).to include("posthog.init")
    end
  end

  describe "the legal pages" do
    it "state the minimum age and the under-age process" do
      [privacy_path, terms_path].each do |path|
        get path

        expect(response.body).to include("at least 16").or include("aged 16 and over")
        expect(response.body).to include("we suspend it and then delete it and its data")
      end
    end
  end
end
