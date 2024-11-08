RSpec.describe ActivitiesSetup::FromParticipation, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(record) }

    let(:record) { build(:participation, participant: participant) }
    let(:participant) { build(:user, id: 42) }

    it "creates expected activity" do
      expect { call }.to change { Activity.count }.by(1)

      expect(Activity.last).to have_attributes(
        receiver_id: 42,
        title: in_array(I18n.t("activities.session_scheduled.titles")),
        content: in_array(I18n.t("activities.session_scheduled.content"))
      )
    end
  end
end
