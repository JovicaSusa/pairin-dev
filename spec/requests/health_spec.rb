require "rails_helper"

RSpec.describe "Health check", type: :request do
  it "is OK when the databases answer" do
    get "/health"

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("OK")
  end

  it "reports a problem without giving details when a database doesn't answer" do
    allow(SolidQueue::Record.connection).to receive(:select_value)
      .and_raise(ActiveRecord::ConnectionNotEstablished, "secret host details")
    allow(Rails.error).to receive(:report)

    get "/health"

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to eq("Unavailable")
    expect(Rails.error).to have_received(:report)
  end

  it "doesn't need a sign-in or redirect the www host" do
    host! "www.pairin.dev"

    get "/health"

    expect(response).to have_http_status(:ok)
  end
end
