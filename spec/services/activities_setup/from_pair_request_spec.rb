RSpec.describe ActivitiesSetup::FromPairRequest, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(record, previous_changes) }

    let(:record) { build(:pair_request, user: user) }
    let(:user) { build(:user, id: 42) }
    let(:previous_changes) { changes }

    context "when record created" do
      let(:changes) { { id: [nil, "1"] } }

      it "creates expected activity" do
        expect { call }.to change { Activity.count }.by(1)

        expect(Activity.last).to have_attributes(
          receiver_id: 42,
          title: in_array(I18n.t("activities.pair_request_created.titles")),
          content: in_array(I18n.t("activities.pair_request_created.content"))
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
