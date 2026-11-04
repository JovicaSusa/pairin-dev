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
end
