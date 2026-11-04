class Message < ApplicationRecord
  MAX_LENGTH = 5000

  belongs_to :offer
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: MAX_LENGTH }

  after_create { offer.update_columns(last_message_at: created_at) }
end
