require 'capybara/rspec'
require 'capybara/cuprite'

Capybara.default_driver = Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 800])
end
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by(:cuprite, using: :chrome, options: {
      js_errors: true,
      headless: %w[0 false].exclude?(ENV["HEADLESS"]),
      slowmo: ENV["SLOWMO"]&.to_f,
      process_timeout: 15,
      timeout: 10,
      browser_options: ENV["DOCKER"] ? { "no-sandbox" => nil } : {}
    })
  end

  config.filter_gems_from_backtrace("capybara", "cuprite", "ferrum")
end
