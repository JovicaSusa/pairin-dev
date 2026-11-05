require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "connects a signed-in user" do
    user = create(:user)

    connect "/cable", env: { "warden" => double(user:) }

    expect(connection.current_user).to eq(user)
  end

  it "refuses anyone signed out" do
    expect { connect "/cable", env: { "warden" => double(user: nil) } }.to have_rejected_connection
  end
end
