FactoryBot.define do
  factory(:availability_window) do
    user
    weekday { 2 }
    start_minute { 18 * 60 }
    end_minute { 20 * 60 }
  end
end
