RSpec.describe "generates expected activites", type: :system do
  include ActiveJob::TestHelper

  let(:current_user) { create(:user) }

  before { sign_in(current_user) }

  context "when pair request created" do
    before { create(:availability_window, user: current_user) }

    it "displays expected activity" do
      visit new_users_pair_request_path

      fill_in "Subject", with: "AAA"
      fill_in "Description", with: "BBB"

      perform_enqueued_jobs do
        click_button "Post partner search"
        expect(page).to have_content("Partner search posted")
      end

      visit activities_path

      expect(page).to have_one_of_the_texts(I18n.t("activities.pair_request_created.titles"))
      expect(page).to have_one_of_the_texts(I18n.t("activities.pair_request_created.content"))
    end
  end

  context "when offer sent" do
    let!(:pair_request) { create(:pair_request) }

    it "creates expected activity" do
      visit pair_requests_path

      click_button "Apply"
      fill_in "What do you want to get out of this?", with: "Finish a course"
      select_option!("How often can you pair?", "Twice a week")
      select_option!("How long can you commit?", "A few weeks")
      fill_in "Your message to #{pair_request.user.name}", with: "Let's hack!"

      perform_enqueued_jobs do
        click_button "Send application"
        expect(page).to have_content("We've emailed the poster")
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
        offer.update!(accepted_at: Time.current)
      end
    end

    it "displays expected activities" do
      visit activities_path

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
