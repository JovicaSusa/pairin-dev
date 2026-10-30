class CreateAvailabilityWindows < ActiveRecord::Migration[7.1]
  def change
    create_table :availability_windows do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :weekday, null: false
      t.integer :start_minute, null: false
      t.integer :end_minute, null: false

      t.timestamps
    end
  end
end
