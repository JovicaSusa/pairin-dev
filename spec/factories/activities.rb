FactoryBot.define do
  factory :activity do
    title { "title" }
    content { "content" }
    receiver factory: :user
  end
end
