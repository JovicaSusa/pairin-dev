class Message < ApplicationRecord
  MAX_LENGTH = 5000

  belongs_to :offer
  # Nobody for a message from Pairin itself, like a chat's closing message.
  belongs_to :sender, class_name: "User", optional: true

  validates :body, presence: true, length: { maximum: MAX_LENGTH }

  after_create { offer.update_columns(last_message_at: created_at) }
  after_create_commit { ConversationsChannel.notify(offer) }
end
