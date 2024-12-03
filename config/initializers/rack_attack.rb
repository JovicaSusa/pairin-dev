Rack::Attack.throttle("req/ip", limit: 1000, period: 5.minutes) do |req|
  unless req.path.start_with?("/assets")
    Rails.logger.error("Rack::Attack Too many requests from IP: #{req.ip}")
    req.ip
  end
end

Rack::Attack.throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == "/users/sign_in" && req.post?
end

Rack::Attack.throttle("logins/email", limit: 5, period: 20.seconds) do |req|
  if req.path == "/users/sign_in" && req.post?
    req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
  end
end

Rack::Attack.throttle("users/sign_up", limit: 3, period: 15.minutes) do |req|
  req.ip if req.path == "/users" && req.post?
end
