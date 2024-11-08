class AddUsersDetails < ActiveRecord::Migration[7.1]
  def change
    change_table :users do |t|
      t.string :language, index: true
      t.text :about
      t.string :country
      t.datetime :date_of_birth
      t.string :level
      t.datetime :programming_since
      t.text :image_data
    end
  end
end
