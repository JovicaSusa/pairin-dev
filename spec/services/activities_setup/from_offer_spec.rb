RSpec.describe ActivitiesSetup::FromOffer, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(record) }

    let(:record) { build(:offer) }

    before do
      Activity.suppress do
        record.save
      end
    end

    context "when record created" do
      it "creates expected activities" do
        expect { call }.to change { Activity.count }.by(2)

        expect(Activity.last(2)).to match_array([
          have_attributes(
            receiver_id: record.pair_request.user_id,
            title: "Fix me",
            content: "Fix me, too"
          ),
          have_attributes(
            receiver_id: record.offerer.id,
            title: "Fix me",
            content: "Fix me, too"
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

        before do
          Activity.suppress do
            create(:offer, pair_request: record.pair_request)
          end
        end

        it "creates expected activities" do
          expect { call }.to change { Activity.count }.by(2)
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
