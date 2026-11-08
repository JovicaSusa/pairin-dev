# confirmed_at: when the session was confirmed, so a session confirmed less than
# an hour before it starts gets no reminder. reminded_at: set as the reminder
# goes out, so each partner gets at most one.
class AddConfirmedAtAndRemindedAtToSessions < ActiveRecord::Migration[7.1]
  def up
    add_column :sessions, :confirmed_at, :datetime
    add_column :sessions, :reminded_at, :datetime

    # Sessions already confirmed: their last change was the confirmation, so
    # updated_at is the best guess. Cancelled ones by a partner were confirmed too.
    execute <<~SQL
      UPDATE sessions SET confirmed_at = updated_at
      WHERE status = 'confirmed' OR (status = 'cancelled' AND cancelled_by_id IS NOT NULL)
    SQL
  end

  def down
    remove_column :sessions, :reminded_at
    remove_column :sessions, :confirmed_at
  end
end
