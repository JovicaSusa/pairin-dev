require "rails_helper"

RSpec.describe "/sessions/index", type: :view do
  before do
    assign(:sessions, [session])
    sign_in(current_user)
  end

  let(:session) { create(:session, sessionable: pair_request, call_link:) }
  let(:current_user) { create(:user) }
  let(:pair_request) { create(:pair_request, user: holder) }
  let(:participation) { create(:participation, participable: session, participant: participant) }

  context "when session held by current user" do
    let(:holder) { current_user }
    let(:participant) { current_user }

    context "when call link set" do
      let(:call_link) { "https://www.call_link.com" }

      it "shows call link with form with call link set" do
        render

        expect(rendered).to include("https://www.call_link.com")
        expect(rendered).to include("Add")
      end
    end

    context "when call link not set" do
      let(:call_link) { nil }

      it "shows call link with form" do
        render

        expect(rendered).to include("Add")
      end
    end
  end

  context "when session not held by current user" do
    let(:other_participant) { create(:user) }
    let(:holder) { other_participant }
    let(:participant) { other_participant }

    context "when call link set" do
      let(:call_link) { "https://www.call_link.com" }

      it "it displays call link" do
        render

        expect(rendered).to include("https://www.call_link.com")
      end
    end

    context "when call link not set" do
      let(:call_link) { nil }

      it "it displays call link info" do
        render

        expect(rendered).to include("The #{session.holder.name} should provide link soon!")
      end
    end
  end
end
