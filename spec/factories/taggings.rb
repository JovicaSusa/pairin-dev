FactoryBot.define do
  factory(:tagging) do
    taggable factory: :pair_request
    tag
  end
end
