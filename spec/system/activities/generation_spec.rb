RSpec.describe "generates expected activites", type: :system do
  include ActiveJob::TestHelper

  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "when pair request created" do
    it "displays expected activity" do
      visit activities_path
      visit users_pair_requests_path

      click_link "New Request"
      fill_in "Subject", with: "AAA"
      fill_in "Description", with: "BBB"
      fill_in "Duration", with: 45
      page.execute_script("document.querySelector('#pair_request_periods_attributes_0_start_at')._flatpickr.setDate(new Date(new Date().getTime() + 24 * 60 * 60 * 1000))")

      perform_enqueued_jobs do
        click_button "Create Pair request"
      end

      visit activities_path

      expect(page).to have_one_of_the_texts(I18n.t("activities.pair_request_created.titles"))
      expect(page).to have_one_of_the_texts(I18n.t("activities.pair_request_created.content"))
    end
  end

  context "when pair request offer accepted" do
    let(:pair_request) { create(:pair_request, user: current_user) }
    let!(:offer) { create(:offer, pair_request:) }

    it "displays expected activity" do
      visit users_pair_requests_path

      within("#pair_requests") { click_link "See applications" }

      perform_enqueued_jobs do
        click_button "Accept"
      end

      visit activities_path

      expect(page).to have_one_of_the_texts(I18n.t("activities.session_scheduled.titles"))
      expect(page).to have_one_of_the_texts(I18n.t("activities.session_scheduled.content"))
    end
  end

  context "when offer sent" do
    let!(:pair_request) { create(:pair_request) }

    it "creates expected activity" do
      visit pair_requests_path

      click_link "Apply"
      fill_in "Message", with: "Let's hack!"

      perform_enqueued_jobs do
        click_button "Apply"
      end

      visit activities_path
    end
  end

  context "when offer accepted" do
    let(:pair_request) { create(:pair_request) }
    let(:offer) { build(:offer, offerer: current_user, pair_request:) }

    before do
      perform_enqueued_jobs do
        Activity.suppress { offer.save! }
        Offers::Accept.call(offer)
      end
    end

    it "displays expected activities" do
      visit activities_path

      expect(page).to have_one_of_the_texts(I18n.t("activities.session_scheduled.titles"))
      expect(page).to have_one_of_the_texts(I18n.t("activities.session_scheduled.content"))
      expect(page).to have_one_of_the_texts(I18n.t("activities.offer_accepted.titles"))
      expect(page).to have_one_of_the_texts(I18n.t("activities.offer_accepted.content"))
    end
  end

  context "when offer rejected" do
    let(:pair_request) { create(:pair_request) }
    let(:current_user_offer) { build(:offer, offerer: current_user, pair_request:) }
    let(:accepted_offer) { build(:offer, pair_request:) }

    before do
      perform_enqueued_jobs do
        Activity.suppress do
          current_user_offer.save!
          accepted_offer.save!
        end
        accepted_offer.update!(accepted_at: Time.zone.now)
      end
    end

    it "displays expected activities" do
      visit activities_path

      expect(page).to have_one_of_the_texts(I18n.t("activities.offer_not_accepted.titles"))
      expect(page).to have_one_of_the_texts(I18n.t("activities.offer_not_accepted.content"))
    end
  end
end
