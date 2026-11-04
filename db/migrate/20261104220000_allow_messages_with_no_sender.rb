# A message with no sender is from Pairin itself, like a chat's closing message.
class AllowMessagesWithNoSender < ActiveRecord::Migration[7.1]
  def change
    change_column_null :messages, :sender_id, true
  end
end
