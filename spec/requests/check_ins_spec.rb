require "rails_helper"

RSpec.describe "Weekly check-ins", type: :request do
  let(:poster) { create(:user, name: "Maya", email: "maya@example.com") }
  let(:partner) { create(:user, name: "Sam", email: "sam@example.com") }
  let(:offer) { create(:offer, pair_request: create(:pair_request, user: poster), offerer: partner) }
  let!(:partnership) do
    offer.post_message(poster, "Hi")
    offer.propose_partnership!(by: partner)
    offer.accept_proposal!(by: poster)
  end

  def run_job = SendWeeklyCheckInsJob.perform_now

  def email_sent = have_enqueued_mail(CheckInMailer, :weekly_email)

  describe "sending" do
    it "sends nothing in the first week" do
      travel 6.days + 23.hours

      expect { run_job }.not_to email_sent
    end

    it "sends each partner one email after a week" do
      travel 7.days + 1.minute

      expect { run_job }.to email_sent.twice

      expect(CheckIn.pluck(:user_id, :week)).to contain_exactly([poster.id, 1], [partner.id, 1])
    end

    it "doesn't send twice in the same week" do
      travel 7.days + 1.minute
      run_job
      travel 1.day

      expect { run_job }.not_to email_sent
    end

    it "sends again the next week" do
      travel 7.days + 1.minute
      run_job
      travel 7.days

      expect { run_job }.to email_sent.twice
      expect(CheckIn.maximum(:week)).to eq(2)
    end

    it "only asks about the latest week after a gap" do
      travel 21.days + 1.minute

      expect { run_job }.to email_sent.twice
      expect(CheckIn.pluck(:week).uniq).to eq([3])
    end

    it "stops when the partnership ends" do
      partnership.end!(by: poster)
      travel 7.days + 1.minute

      expect { run_job }.not_to email_sent
    end

    it "stops when the chat has ended because someone turned 18" do
      teen_poster = create(:user, date_of_birth: 17.years.ago.to_date)
      turning = create(:user, date_of_birth: 18.years.ago.to_date + 3)
      teens = create(:offer, pair_request: create(:pair_request, user: teen_poster), offerer: turning)
      teens.post_message(teen_poster, "Hi")
      teens.propose_partnership!(by: turning)
      together = teens.accept_proposal!(by: teen_poster)
      partnership.end!(by: poster)
      travel 7.days + 1.minute

      expect(together.reload).to be_ended
      expect { run_job }.not_to email_sent
    end
  end

  describe "the email" do
    let(:check_in) { CheckIn.create!(partnership:, user: partner, week: 1) }
    let(:mail) { CheckInMailer.with(check_in:).weekly_email }

    it "asks about the partner, with Yes and No links, and keeps addresses private" do
      expect(mail.to).to eq(["sam@example.com"])
      expect(mail.subject).to eq("Did you and Maya work together this week?")
      expect(mail.body.encoded).to include("answer=yes", "answer=no", "/check-ins/")
      expect(mail.body.encoded).not_to include("maya@example.com")
    end
  end

  describe "answering, with no login" do
    let(:check_in) { CheckIn.create!(partnership:, user: partner, week: 1) }
    let(:token) { check_in.generate_token_for(:answer) }

    it "doesn't store anything just from opening the link" do
      get check_in_path(token:, answer: "yes")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Confirm: Yes")
      expect(check_in.reload).not_to be_answered
    end

    it "stores Yes once confirmed" do
      post check_in_path(token:), params: { answer: "yes" }

      expect(check_in.reload).to have_attributes(worked_together: true)
      expect(check_in).to be_answered
      follow_redirect!
      expect(response.body).to include("Thanks, got it")
    end

    it "stores No" do
      post check_in_path(token:), params: { answer: "no" }

      expect(check_in.reload).to have_attributes(worked_together: false)
      expect(check_in).to be_answered
    end

    it "ignores anything else" do
      post check_in_path(token:), params: { answer: "maybe" }

      expect(check_in.reload).not_to be_answered
    end

    it "keeps the token away from analytics and search engines" do
      get check_in_path(token:)

      expect(response.body).not_to include("posthog")
      expect(response.headers["X-Robots-Tag"]).to include("noindex")
    end

    it "refuses a tampered token" do
      get check_in_path(token: "#{token}x")
      expect(response).to have_http_status(:not_found)

      post check_in_path(token: "nope"), params: { answer: "yes" }
      expect(response).to have_http_status(:not_found)
      expect(check_in.reload).not_to be_answered
    end
  end

  describe "the Workspace markers" do
    def weeks
      sign_in(poster)
      get partner_path(partnership)
      JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"]).dig("props", "partnership", "weeks")
    end

    before { travel 14.days + 1.minute }

    it "counts a week when at least one partner said Yes" do
      CheckIn.create!(partnership:, user: poster, week: 1).answer!(false)
      CheckIn.create!(partnership:, user: partner, week: 1).answer!(true)
      CheckIn.create!(partnership:, user: poster, week: 2).answer!(false)
      CheckIn.create!(partnership:, user: partner, week: 2)

      expect(weeks).to eq([{ "week" => 1, "worked_together" => true }, { "week" => 2, "worked_together" => false }])
    end

    it "says when the next one goes out" do
      sign_in(poster)
      get partner_path(partnership)

      next_at = JSON.parse(Nokogiri::HTML(response.body).at("[data-page]")["data-page"]).dig("props", "partnership", "next_check_in_at")
      expect(Time.iso8601(next_at)).to be_within(1.second).of(partnership.created_at + 21.days)
    end
  end

  it "is deleted with either account" do
    CheckIn.create!(partnership:, user: partner, week: 1)

    expect { poster.destroy! }.to change(CheckIn, :count).by(-1)
  end
end
