class CreatePairRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :pair_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.text :description, null: false
      t.string :subject, null: false

      t.timestamps
    end
  end
end
