FactoryBot.define do
  factory(:participation) do
    participable factory: :session
    participant factory: :user
    role { "initiator" }
  end
end
