# Who withdrew or cancelled a session. Left empty when ending the partnership
# cancelled it, so the page can say that instead of naming someone.
class AddCancelledByToSessions < ActiveRecord::Migration[7.1]
  def change
    add_reference :sessions, :cancelled_by, foreign_key: { to_table: :users }
  end
end
