RSpec.describe PairRequests::InstantJoin, type: :unit do
  describe ".call" do
    subject(:call) { described_class.call(pair_request.id, joiner) }

    let(:pair_request) { create(:pair_request, :immediate) }
    let(:joiner) { create(:user) }

    it "returns success" do
      expect(call.success?).to be true
    end

    it "creates an accepted offer for the joiner using the immediate period" do
      expect { call }.to change { pair_request.offers.count }.by(1)

      offer = pair_request.reload.offers.last

      expect(offer.offerer).to eq joiner
      expect(offer.period).to eq pair_request.periods.first
      expect(offer).to be_accepted
    end

    it "creates a session with both participants" do
      expect { call }.to change { Session.count }.by(1)

      session = Session.last

      expect(session.sessionable).to eq pair_request
      expect(session.participants).to contain_exactly(pair_request.user, joiner)
    end

    context "when the joiner is the pair request's own user" do
      let(:joiner) { pair_request.user }

      it "returns failure" do
        expect(call.success?).to be false
      end

      it "doesn't create an offer or a session" do
        expect { call }
          .to not_change { Offer.count }
          .and not_change { Session.count }
      end
    end

    context "when the pair request is not in immediate mode" do
      let(:pair_request) { create(:pair_request) }

      it "returns failure" do
        expect(call.success?).to be false
      end
    end

    context "when the pair request already has an accepted offer" do
      before { create(:offer, :accepted, pair_request:) }

      it "returns failure" do
        expect(call.success?).to be false
      end

      it "doesn't create a new session" do
        expect { call }.not_to change { Session.count }
      end
    end

    context "when the pair request requires approval" do
      let(:pair_request) { create(:pair_request, :immediate, requires_approval: true) }

      it "returns failure" do
        expect(call.success?).to be false
      end

      it "doesn't create an offer or a session" do
        expect { call }
          .to not_change { Offer.count }
          .and not_change { Session.count }
      end
    end

    context "when two joiners attempt to instant-join the same pair request at once" do
      self.use_transactional_tests = false

      after do
        Session.delete_all
        Participation.delete_all
        Offer.delete_all
        Period.delete_all
        PairRequest.delete_all
        User.delete_all
      end

      it "only lets one succeed and creates a single session" do
        pair_request = create(:pair_request, :immediate)
        joiner_a = create(:user)
        joiner_b = create(:user)
        results = Queue.new

        threads = [joiner_a, joiner_b].map do |joiner|
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              results << PairRequests::InstantJoin.call(pair_request.id, joiner)
            end
          end
        end
        threads.each(&:join)

        outcomes = Array.new(2) { results.pop }

        expect(outcomes.count(&:success?)).to eq 1
        expect(outcomes.count(&:failure?)).to eq 1
        expect(Session.where(sessionable: pair_request).count).to eq 1
      end
    end
  end
end
