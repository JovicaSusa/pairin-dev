class CreateParticipations < ActiveRecord::Migration[7.1]
  def change
    create_table :participations do |t|
      t.references :participable, polymorphic: true, null: false
      t.references :participant, null: false, foreign_key: { to_table: :users }
      t.string :role, null: false
    end
  end
end
