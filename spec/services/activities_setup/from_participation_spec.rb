RSpec.describe ActivitiesSetup::FromParticipation, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(record, previous_changes) }

    let(:record) { build(:participation, participant: participant) }
    let(:participant) { build(:user, id: 42) }
    let(:previous_changes) { changes }

    context "when record created" do
      let(:changes) { { id: [nil, "1"] } }

      it "creates expected activity" do
        expect { call }.to change { Activity.count }.by(1)

        expect(Activity.last).to have_attributes(
          receiver_id: 42,
          title: in_array(I18n.t("activities.session_scheduled.titles")),
          content: in_array(I18n.t("activities.session_scheduled.content"))
        )
      end
    end

    context "when record not created" do
      let(:changes) { { updated_at: [nil, Time.current] } }

      it "doesn't create activity" do
        expect { call }.not_to change { Activity.count }
      end
    end
  end
end
