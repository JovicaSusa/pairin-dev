require "rails_helper"

RSpec.describe DeleteSuspendedAccountsJob, type: :job do
  let(:perform) { described_class.perform_now }

  def suspended(ago)
    create(:user).tap { |user| user.update_columns(suspended_at: ago.ago) }
  end

  it "deletes accounts past the grace period, with their data" do
    user = suspended(15.days)
    search = create(:pair_request, user:)
    their_offer = create(:offer, offerer: user)
    offer_on_their_search = create(:offer, pair_request: search)
    window = create(:availability_window, user:)
    create(:session, sessionable: search).participations.create!(participant: user, role: Participation::ROLE_INITIATOR)
    user.activities.create!(title: "Hi", content: "There")
    poster_of_their_offer = their_offer.pair_request

    perform

    expect(User.exists?(user.id)).to be(false)
    expect(PairRequest.exists?(search.id)).to be(false)
    expect(Offer.exists?(their_offer.id)).to be(false)
    expect(Offer.exists?(offer_on_their_search.id)).to be(false)
    expect(AvailabilityWindow.exists?(window.id)).to be(false)
    expect(Participation.where(participant_id: user.id)).to be_empty
    expect(Activity.where(receiver_id: user.id)).to be_empty
    expect(PairRequest.exists?(poster_of_their_offer.id)).to be(true)
  end

  it "leaves accounts still inside the grace period" do
    user = suspended(13.days)

    perform

    expect(User.exists?(user.id)).to be(true)
  end

  it "leaves everyone else alone" do
    user = create(:user)

    perform

    expect(User.exists?(user.id)).to be(true)
  end

  it "keeps going when one account can't be deleted" do
    stuck = suspended(15.days)
    deletable = suspended(16.days)
    allow_any_instance_of(User).to receive(:destroy!).and_wrap_original do |original, *args|
      raise ActiveRecord::RecordNotDestroyed.new("stuck", original.receiver) if original.receiver == stuck

      original.call(*args)
    end

    perform

    expect(User.exists?(stuck.id)).to be(true)
    expect(User.exists?(deletable.id)).to be(false)
  end
end
