class CreateActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :activities do |t|
      t.text :content
      t.references :receiver, null: false, foreign_key: { to_table: :users }
      t.string :title
      t.datetime :seen_at

      t.timestamps
    end
  end
end
