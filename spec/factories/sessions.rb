FactoryBot.define do
  factory(:session) do
    sessionable factory: :pair_request
    start_at { 45.minutes.from_now }
    end_at { 115.minutes.from_now }
  end
end
