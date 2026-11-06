class CreateSharedLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :shared_links do |t|
      t.references :partnership, null: false, foreign_key: true
      t.references :added_by, null: false, foreign_key: { to_table: :users }
      t.string :url, null: false
      t.text :note
      t.timestamps
    end
  end
end
