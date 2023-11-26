class CreatePairRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :pair_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.text :description
      t.string :subject

      t.timestamps
    end
  end
end
