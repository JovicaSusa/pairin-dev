class CreateOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :offers do |t|
      t.references :offerer, null: false, foreign_key: { to_table: :users }
      t.references :pair_request, null: false, foreign_key: true
      t.text :message

      t.timestamps
    end
  end
end
