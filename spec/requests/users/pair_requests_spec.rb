require 'rails_helper'

RSpec.describe "Users::PairRequests", type: :request do
  describe "POST /users/pair_requests" do
    let(:current_user) { create(:user) }

    before { sign_in(current_user) }

    context "when mode is immediate" do
      let(:params) do
        {
          subject: "AAA",
          description: "BBB",
          duration: 45,
          mode: "immediate",
          wait_minutes: 30
        }
      end

      it "schedules the immediate expiry job for start_at + wait_minutes" do
        freeze_time do
          expect { post users_pair_requests_path, params: }
            .to have_enqueued_job(PairRequests::ImmediateExpiryJob).at(30.minutes.from_now)

          pair_request = current_user.pair_requests.find_by!(subject: "AAA")

          expect(enqueued_jobs.last[:args]).to eq [pair_request.id]
        end
      end
    end

    context "when mode is scheduled" do
      let(:params) do
        {
          subject: "AAA",
          description: "BBB",
          duration: 45,
          mode: "scheduled",
          periods_attributes: [{ start_at: 1.day.from_now }]
        }
      end

      it "does not schedule the immediate expiry job" do
        expect { post users_pair_requests_path, params: }
          .not_to have_enqueued_job(PairRequests::ImmediateExpiryJob)
      end
    end
  end
end
