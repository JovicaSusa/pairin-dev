require "rails_helper"

# The privacy policy promises that error reports leave out what people type into forms.
RSpec.describe "Honeybadger error reports" do
  let(:config) do
    Honeybadger::Config.new(logger: Logger.new(IO::NULL), framework: :rails, root: Rails.root.to_s,
                            env: "production", :"config.path" => Rails.root.join("config/honeybadger.yml").to_s).load!
  end

  let(:report) do
    env = Rack::MockRequest.env_for(
      "/conversations/1/messages?token=PRIVATE-TOKEN",
      method: "POST",
      params: { "message" => { "body" => "PRIVATE-CHAT-TEXT" }, "user" => { "email" => "PRIVATE-EMAIL" } },
      "REMOTE_ADDR" => "203.0.113.9",
      "HTTP_COOKIE" => "_session=PRIVATE-COOKIE",
      "HTTP_AUTHORIZATION" => "PRIVATE-AUTH"
    )
    env["rack.session"] = { "secret_value" => "PRIVATE-SESSION" }
    env["action_dispatch.parameter_filter"] = Rails.application.config.filter_parameters

    Honeybadger::Notice.new(config, exception: RuntimeError.new("boom"), rack_env: env).to_json
  end

  it "leaves out form data, the session, cookies and tokens" do
    expect(report).not_to include("PRIVATE-")
  end

  it "keeps what's needed to find the problem" do
    expect(report).to include("boom", "/conversations/1/messages")
  end
end
