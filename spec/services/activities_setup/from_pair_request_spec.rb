RSpec.describe ActivitiesSetup::FromPairRequest, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(record) }

    let(:record) { build(:pair_request, user: user) }
    let(:user) { build(:user, id: 42) }

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
