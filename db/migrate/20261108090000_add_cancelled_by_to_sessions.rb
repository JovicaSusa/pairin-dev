# Who cancelled a session, to say "You cancelled" or "Sam cancelled". Empty
# when ending the partnership cancelled it.
class AddCancelledByToSessions < ActiveRecord::Migration[7.1]
  def change
    add_reference :sessions, :cancelled_by, foreign_key: { to_table: :users }
  end
end
