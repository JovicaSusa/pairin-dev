require "rails_helper"

RSpec.describe ConversationsChannel, type: :channel do
  let(:user) { create(:user) }

  it "streams only the subscriber's own updates" do
    stub_connection(current_user: user)

    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(user)
    expect(subscription.streams.size).to eq(1)
  end

  describe ".notify" do
    let(:offer) { create(:offer) }

    it "signals both people, with an id and no message text" do
      expect { described_class.notify(offer) }
        .to have_broadcasted_to(offer.offerer).from_channel(described_class).with(conversation_id: offer.id)
        .and have_broadcasted_to(offer.poster).from_channel(described_class).with(conversation_id: offer.id)
    end

    it "doesn't signal anyone else" do
      offer
      stranger = create(:user)

      expect { described_class.notify(offer) }.not_to have_broadcasted_to(stranger).from_channel(described_class)
    end

    it "doesn't fail the message when the signal fails" do
      allow(described_class).to receive(:broadcast_to).and_raise(StandardError, "cable down")
      offer

      expect { offer.post_message(offer.poster, "Hi") }.to change(offer.messages, :count).by(1)
    end
  end
end
