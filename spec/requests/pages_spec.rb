require "rails_helper"

RSpec.describe "Legal pages", type: :request do
  it "says private messages are stored and what happens to them" do
    get privacy_path

    expect(response.body).to include("we store your messages")
    expect(response.body).to include("If someone reports a chat")
    expect(response.body).to include("every conversation that person was part of is deleted")
  end

  it "says so in the terms too" do
    get terms_path

    expect(response.body).to include("stored by Pairin")
    expect(response.body).to include("if a chat is reported, we may read it")
    expect(response.body).to include("conversation is deleted for both of them")
  end

  it "says in the terms that Pairin only introduces members" do
    get terms_path

    expect(response.body).to include("Pairin introduces you to other members")
    expect(response.body).to include("we aren't responsible for what happens between you")
  end

  it "describes the chat-first product, with no retros or sessions left over" do
    [ privacy_path, terms_path ].each do |path|
      get path

      expect(response.body).not_to match(/retro|session summar|pair-programming session|pairing partner/i)
      expect(response.body).to include("Last updated November 5, 2026")
    end
  end

  it "says what partners share in a Workspace and who sees a reason for ending" do
    get privacy_path

    expect(response.body).to include("they share a private Workspace", "only we see it", "using the link in the email")
  end
end
