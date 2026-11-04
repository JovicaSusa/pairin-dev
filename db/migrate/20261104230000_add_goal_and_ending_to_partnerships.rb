class AddGoalAndEndingToPartnerships < ActiveRecord::Migration[7.1]
  def change
    add_column :partnerships, :goal, :text
    add_column :partnerships, :ended_at, :datetime
    add_reference :partnerships, :ended_by, foreign_key: { to_table: :users }
  end
end
