RSpec.describe ActivitiesSetup::FromOffer, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(record) }

    let(:record) { build(:offer, period: pair_request.periods.first, pair_request:) }
    let(:pair_request) { create(:pair_request) }

    before do
      Activity.suppress do
        record.save!
      end
    end

    context "when record created" do
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
      before do
        Activity.suppress do
          record.update(**attrs)
        end
      end

      context "when offer just got accepted" do
        let(:attrs) { { accepted_at: Time.zone.now } }
        let(:offer_not_accepted) { build(:offer, pair_request: record.pair_request) }

        before do
          Activity.suppress do
            offer_not_accepted.save!
          end
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
        let(:attrs) { { message: "_" } }

        it "doesn't create activities" do
          expect { call }.not_to change { Activity.count }
        end
      end
    end
  end
end