class ChangeProgrammingSinceToYear < ActiveRecord::Migration[7.1]
  def up
    change_column :users, :programming_since, 'integer USING EXTRACT(YEAR FROM programming_since)::integer'
  end

  def down
    change_column :users, :programming_since, 'timestamp USING make_date(programming_since, 1, 1)::timestamp'
  end
end
