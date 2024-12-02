FactoryBot.define do
  factory(:period) do
    periodable { association :pair_request, with_periods: false }
    end_at { 95.minutes.from_now }
    start_at { 30.minutes.from_now }
  end
end
