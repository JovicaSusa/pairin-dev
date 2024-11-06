RSpec.describe ActivitiesSetup::FromParticipation, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(record) }

    let(:record) { build(:participation, participant: participant) }
    let(:participant) { build(:user, id: 42) }

    it "creates expected activity" do
      expect { call }.to change { Activity.count }.by(1)

      expect(Activity.last).to have_attributes(
        receiver_id: 42,
        title: "Fix me",
        content: "Fix me, too"
      )
    end
  end
end
