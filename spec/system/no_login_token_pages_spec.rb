require "rails_helper"

# The pages reached from an emailed, signed link (no login) answer with a form
# POST. Run them in a real browser with forgery protection on, as in
# production: a too-strict Referrer-Policy makes the browser send `Origin: null`,
# and Rails then rejects every answer with a 422.
RSpec.describe "answering from an emailed link, with no login", type: :system do
  around do |example|
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  let(:poster) { create(:user, name: "Maya") }
  let(:partner) { create(:user, name: "Sam") }
  let(:offer) { create(:offer, pair_request: create(:pair_request, user: poster), offerer: partner) }
  let(:partnership) do
    offer.post_message(poster, "Hi")
    offer.propose_partnership!(by: partner)
    offer.accept_proposal!(by: poster)
  end

  it "stores the weekly check-in answer" do
    check_in = CheckIn.create!(partnership:, user: partner, week: 1)

    visit check_in_path(token: check_in.generate_token_for(:answer), answer: "yes")
    click_button "Confirm: Yes"

    expect(page).to have_content("Thanks, got it")
    expect(check_in.reload.worked_together).to be(true)
  end

  it "stores the \"Did it happen?\" answer" do
    session = create(:session, partnership:, proposed_by: poster, status: "confirmed")
    answer = session.answers.create!(user: partner)

    visit session_answer_path(token: answer.generate_token_for(:answer))
    click_button "Yes"

    expect(page).to have_content("Thanks, got it")
    expect(answer.reload).to be_answered
  end

  it "pauses a search" do
    search = create(:pair_request, user: poster)

    visit request_pause_path(token: search.generate_token_for(:pause))
    click_button "Pause this search"

    expect(page).to have_content("Your partner search is paused")
    expect(search.reload).to be_paused
  end

  it "turns a paused search back on" do
    search = create(:pair_request, user: poster)
    search.switch_off!

    visit request_resumption_path(token: search.generate_token_for(:resume))
    click_button "Turn it back on"

    expect(page).to have_no_content("Still looking for a partner?")
    expect(search.reload).not_to be_paused
  end
end
