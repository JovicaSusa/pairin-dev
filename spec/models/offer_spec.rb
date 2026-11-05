RSpec.describe Offer, type: :model do
  # describe "validations" do
  #   it { should validate_presence_of(:message) }
  #   it { should validate_uniqueness_of(:pair_request_id).scoped_to(:offerer_id) }
  # end
  it_behaves_like "activity generatable", :offer

  describe "application answers" do
    it "requires a goal, how often and how long" do
      offer = build(:offer, goal: "", how_often: nil, how_long: nil)

      expect(offer).not_to be_valid
      expect(offer.errors.attribute_names).to include(:goal, :how_often, :how_long)
    end

    it "only accepts the listed options" do
      offer = build(:offer, how_often: "daily", how_long: "forever")

      expect(offer).not_to be_valid
      expect(offer.errors.attribute_names).to include(:how_often, :how_long)
    end

    it "requires the applicant to have a level" do
      offer = build(:offer, offerer: create(:user, level: nil))

      expect(offer).not_to be_valid
      expect(offer.errors[:level]).to be_present
    end

    it "leaves old applications without answers valid" do
      offer = create(:offer)
      offer.update_columns(goal: nil, how_often: nil, how_long: nil)

      expect(offer.reload).to be_valid
      expect(offer.how_often_label).to be_nil
    end

    it "gives readable labels" do
      offer = build(:offer, how_often: "twice_a_week", how_long: "open_ended")

      expect([offer.how_often_label, offer.how_long_label]).to eq(["Twice a week", "Open-ended"])
    end
  end

  it "starts its thread with the application's message" do
    offer = create(:offer, message: "Hello there")

    expect(offer.messages.map { |m| [m.sender, m.body] }).to eq([[offer.offerer, "Hello there"]])
    expect(offer.reload.last_message_at).to be_present
  end

  it "refuses an application message too long for a thread" do
    expect(build(:offer, message: "x" * (Message::MAX_LENGTH + 1))).not_to be_valid
  end

  it "doesn't need a time" do
    expect(build(:offer)).to be_valid
    expect(create(:offer).period).to be_nil
  end

  it "keeps an old application's time" do
    offer = create(:offer, with_old_period: true)

    expect(offer.reload.period.periodable).to eq(offer)
  end

  describe "its clock, which starts when someone applies" do
    let(:offer) { create(:offer) }

    it "reminds the poster after 24 hours" do
      expect(offer.reminder_at).to eq(offer.created_at + 24.hours)
    end

    it "is overdue after 72 hours with no answer" do
      expect(offer.expires_at).to eq(offer.created_at + 72.hours)

      travel_to(offer.created_at + 72.hours - 1.minute) { expect(offer).not_to be_overdue }
      travel_to(offer.created_at + 72.hours + 1.second) { expect(offer).to be_overdue }
    end

    it "stops when the poster replies" do
      offer.post_message(offer.poster, "Hi")

      expect(offer).not_to be_unanswered
      travel_to(offer.expires_at + 1.day) { expect(offer).not_to be_overdue }
    end

    it "stops when either person ends it" do
      offer.not_a_match!(by: offer.offerer)

      expect(offer).not_to be_unanswered
    end

    it "treats an application accepted the old way as answered" do
      expect(create(:offer, :accepted)).not_to be_unanswered
    end

    it "ignores an old application's time" do
      old = create(:offer, with_old_period: true)

      travel_to(old.period.start_at + 1.hour) { expect(old).not_to be_overdue }
    end
  end

  describe ".accepted" do
    subject(:accepted) { described_class.accepted }

    let!(:accepted_offer) { create(:offer, :accepted) }
    let!(:not_accepted_offer) { create(:offer) }

    it { is_expected.to contain_exactly(accepted_offer) }
  end
end
