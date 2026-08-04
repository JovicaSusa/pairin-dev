class AddIndexOnSessionsEndAt < ActiveRecord::Migration[7.1]
  def change
    add_index :sessions, :end_at
  end
end
