FactoryBot.define do
  factory(:period) do
    periodable factory: :pair_request
    end_at { 95.minutes.from_now }
    start_at { 30.minutes.from_now }
  end
end
