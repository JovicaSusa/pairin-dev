class CreateMessagesAndAddConversationStateToOffers < ActiveRecord::Migration[7.1]
  def up
    create_table :messages do |t|
      t.references :offer, null: false, foreign_key: true, index: false
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false

      t.timestamps
    end
    add_index :messages, [:offer_id, :created_at]

    add_column :offers, :replied_at, :datetime
    add_column :offers, :last_message_at, :datetime
    add_column :offers, :ended_at, :datetime
    add_reference :offers, :ended_by, foreign_key: { to_table: :users }
    add_column :offers, :end_reason, :text
    add_index :offers, :last_message_at

    # Each application's message is the first message of its thread, and an
    # application accepted the old way already counts as answered.
    execute <<~SQL
      INSERT INTO messages (offer_id, sender_id, body, created_at, updated_at)
      SELECT id, offerer_id, message, created_at, created_at FROM offers
    SQL
    execute "UPDATE offers SET last_message_at = created_at, replied_at = accepted_at"
  end

  def down
    remove_reference :offers, :ended_by, foreign_key: { to_table: :users }
    remove_column :offers, :replied_at
    remove_column :offers, :last_message_at
    remove_column :offers, :ended_at
    remove_column :offers, :end_reason
    drop_table :messages
  end
end
