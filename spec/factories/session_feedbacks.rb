FactoryBot.define do
  factory(:session_feedback) do
    session
    participant factory: :user

    went_well { SessionFeedback::WENT_WELL_VALUES.sample }
    learned { Faker::Lorem.sentence(word_count: 10) }
    notes { Faker::Lorem.sentence(word_count: 10) }
  end
end
