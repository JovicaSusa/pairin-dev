RSpec.describe ActivitiesSetup::FromOffer, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(record, previous_changes) }

    let(:record) { build(:offer, offerer: user, pair_request: pair_request) }
    let(:pair_request) { build(:pair_request, user: user) }
    let(:user) { create(:user) }
    let(:previous_changes) { changes }

    before { pair_request.offers << record }

    context "when record created" do
      let(:changes) { { id: [nil, "1"] } }

      it "creates expected activities" do
        expect { call }.to change { Activity.count }.by(2)

        expect(Activity.last(2)).to match_array([
          have_attributes(
            receiver_id: record.pair_request.user_id,
            title: in_array(I18n.t("activities.received_offer.titles")),
            content: in_array(I18n.t("activities.received_offer.content"))
          ),
          have_attributes(
            receiver_id: record.offerer.id,
            title: in_array(I18n.t("activities.sent_offer.titles")),
            content: in_array(I18n.t("activities.sent_offer.content"))
          )
        ])
      end
    end

    context "when record updated" do
      context "when offer just got accepted" do
        let(:changes) { { accepted_at: [nil, Time.current] } }
        let(:offer_not_accepted) { build(:offer) }

        before do
          pair_request.offers << offer_not_accepted
        end

        it "creates expected activities" do
          expect { call }.to change { Activity.count }.by(2)

          expect(Activity.last(2)).to match_array([
            have_attributes(
              receiver_id: record.offerer.id,
              title: in_array(I18n.t("activities.offer_accepted.titles")),
              content: in_array(I18n.t("activities.offer_accepted.content"))
            ),
            have_attributes(
              receiver_id: offer_not_accepted.offerer.id,
              title: in_array(I18n.t("activities.offer_not_accepted.titles")),
              content: in_array(I18n.t("activities.offer_not_accepted.content"))
            )
          ])
        end
      end

      context "when didn't just got accepted" do
        let(:changes) { { message: ["ho", "hey"] } }

        it "doesn't create activities" do
          expect { call }.not_to change { Activity.count }
        end
      end
    end
  end
end
