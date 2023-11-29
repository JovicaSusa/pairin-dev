class CreatePeriods < ActiveRecord::Migration[7.1]
  def change
    create_table :periods do |t|
      t.references :periodable, polymorphic: true, null: false
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false

      t.timestamps
    end
  end
end
