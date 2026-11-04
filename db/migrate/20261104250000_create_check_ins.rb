class CreateCheckIns < ActiveRecord::Migration[7.1]
  def change
    create_table :check_ins do |t|
      t.references :partnership, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.integer :week, null: false
      t.boolean :worked_together
      t.datetime :answered_at

      t.timestamps
    end
    # One email per person, per week of the partnership.
    add_index :check_ins, [:partnership_id, :user_id, :week], unique: true
  end
end
