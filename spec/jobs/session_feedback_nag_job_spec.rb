require "rails_helper"

RSpec.describe SessionFeedbackNagJob, type: :job do
  describe "#perform" do
    subject(:perform) { described_class.perform_now(session.id) }

    let(:session) { create(:session, :past) }

    it "creates an activity for each participant missing feedback" do
      expect { perform }.to change { Activity.count }.by(2)

      activities = Activity.last(2)

      expect(activities.map(&:receiver)).to match_array(session.participants)
      expect(activities).to all(have_attributes(
        title: be_in(I18n.t("activities.retro_nag.titles")),
        content: be_in(I18n.t("activities.retro_nag.content"))
      ))
    end

    it "sends the retro nag mailer to each participant missing feedback" do
      expect { perform }.to have_enqueued_mail(SessionMailer, :retro_nag_email).twice
    end

    context "when the session has been destroyed" do
      before { session.destroy! }

      it "does not raise and does not create an activity" do
        expect { perform }.not_to change { Activity.count }
      end

      it "does not send mail" do
        expect { perform }.not_to have_enqueued_mail(SessionMailer, :retro_nag_email)
      end
    end

    context "when a participant already submitted feedback" do
      let(:already_submitted) { session.participants.first }

      before { create(:session_feedback, session:, participant: already_submitted) }

      it "only nags the participant missing feedback" do
        expect { perform }.to change { Activity.count }.by(1)

        expect(Activity.last.receiver).to eq(session.other_participant(already_submitted))
      end

      it "only sends mail to the participant missing feedback" do
        expect { perform }.to have_enqueued_mail(SessionMailer, :retro_nag_email).once
      end
    end

    context "when all participants already submitted feedback" do
      before do
        session.participants.each { |participant| create(:session_feedback, session:, participant:) }
      end

      it "does not create an activity" do
        expect { perform }.not_to change { Activity.count }
      end

      it "does not send mail" do
        expect { perform }.not_to have_enqueued_mail(SessionMailer, :retro_nag_email)
      end
    end
  end
end
