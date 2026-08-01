class AddModeAndScheduleFieldsToPairRequests < ActiveRecord::Migration[7.1]
  def change
    change_table :pair_requests do |t|
      t.string :mode, null: false, default: "scheduled", index: true
      t.integer :wait_minutes
      t.boolean :requires_approval, null: false, default: false
      t.text :goal
      t.string :platform
      t.string :pairing_tool
      t.text :plan
    end
  end
end
