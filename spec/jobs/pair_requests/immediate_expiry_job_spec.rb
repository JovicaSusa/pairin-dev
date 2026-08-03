require 'rails_helper'

RSpec.describe PairRequests::ImmediateExpiryJob, type: :job do
  describe "#perform" do
    subject(:perform) { described_class.perform_now(pair_request.id) }

    let(:pair_request) do
      pr = create(:pair_request, :immediate, wait_minutes: 15, with_periods: false)
      period = create(:period, periodable: pr, start_at: Time.current)
      period.update_column(:start_at, 20.minutes.ago)
      pr
    end

    it "creates an activity for the requester" do
      expect { perform }.to change { Activity.count }.by(1)

      activity = Activity.last

      expect(activity.receiver).to eq pair_request.user
      expect(activity.title).to be_in(I18n.t("activities.immediate_expired.titles"))
      expect(activity.content).to be_in(I18n.t("activities.immediate_expired.content"))
    end

    it "sends the immediate expired mailer" do
      expect { perform }.to have_enqueued_mail(PairRequestMailer, :immediate_expired_email)
    end

    context "when the pair request has been destroyed" do
      before { pair_request.destroy! }

      it "does not raise and does not create an activity" do
        expect { perform }.not_to change { Activity.count }
      end

      it "does not send mail" do
        expect { perform }.not_to have_enqueued_mail(PairRequestMailer, :immediate_expired_email)
      end
    end

    context "when the pair request is already matched" do
      before { create(:offer, :accepted, pair_request:) }

      it "does not create an activity" do
        expect { perform }.not_to change { Activity.count }
      end
    end

    context "when the pair request is no longer immediate mode" do
      before { pair_request.update!(mode: "scheduled") }

      it "does not create an activity" do
        expect { perform }.not_to change { Activity.count }
      end
    end

    context "when the wait was extended after this job was scheduled (stale job)" do
      let(:pair_request) { create(:pair_request, :immediate, wait_minutes: 30) }

      before { PairRequests::ExtendWait.call(pair_request) }

      it "no-ops, since the current deadline is now later than this stale execution" do
        expect { perform }.not_to change { Activity.count }
      end

      it "still fires once the (later) current deadline actually passes" do
        travel_to 31.minutes.from_now do
          expect { perform }.to change { Activity.count }.by(1)
        end
      end
    end
  end
end
