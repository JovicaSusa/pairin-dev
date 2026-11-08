# One partner's answer to "Did it happen?" after a confirmed session. The row is
# created when the email goes out, so each partner is asked at most once.
class CreateSessionAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :session_answers do |t|
      t.references :session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :happened
      t.datetime :answered_at
      t.timestamps
    end

    add_index :session_answers, [:session_id, :user_id], unique: true
  end
end
