class AddEmailOptOutsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :suggestions_opted_out_at, :datetime
    add_column :users, :announcements_opted_out_at, :datetime
  end
end
