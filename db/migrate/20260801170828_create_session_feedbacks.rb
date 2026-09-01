class CreateSessionFeedbacks < ActiveRecord::Migration[7.1]
  def change
    create_table :session_feedbacks do |t|
      t.references :session, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: { to_table: :users }
      t.string :went_well
      t.text :learned
      t.text :notes
      t.text :code_snippet
      t.string :code_snippet_language

      t.timestamps
    end

    add_index :session_feedbacks, [:session_id, :participant_id], unique: true
  end
end
