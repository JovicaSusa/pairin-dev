RSpec.describe ActivitiesSetup::FromSessionFeedback, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(record, previous_changes) }

    let(:record) { create(:session_feedback, session: session, participant: participant) }
    let(:session) { create(:session, :past) }
    let(:participant) { session.participants.first }
    let(:other_participant) { session.other_participant(participant) }
    let(:previous_changes) { changes }

    context "when record created" do
      let(:changes) { { id: [nil, "1"] } }

      it "creates an activity for the other participant" do
        expect { call }.to change { Activity.count }.by(1)

        expect(Activity.last).to have_attributes(
          receiver_id: other_participant.id,
          title: in_array(I18n.t("activities.session_feedback_received.titles")),
          content: in_array(I18n.t("activities.session_feedback_received.content"))
        )
      end
    end

    context "when record not created" do
      let(:changes) { { updated_at: [nil, Time.current] } }

      it "doesn't create an activity" do
        expect { call }.not_to change { Activity.count }
      end
    end
  end
end
