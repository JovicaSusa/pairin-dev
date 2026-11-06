# Sessions were booked on a partner search, with participations saying who
# came. They now belong to a partnership: one partner proposes, the other
# answers. Production had no sessions, and participations only ever pointed at
# sessions, so both start empty.
class ReshapeSessionsForPartnerships < ActiveRecord::Migration[7.1]
  def up
    execute "DELETE FROM sessions"
    drop_table :participations

    remove_reference :sessions, :sessionable, polymorphic: true, index: true
    add_reference :sessions, :partnership, null: false, foreign_key: true
    add_reference :sessions, :proposed_by, null: false, foreign_key: { to_table: :users }
    add_column :sessions, :status, :string, null: false, default: "proposed"
    add_index :sessions, [:partnership_id, :start_at]
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
