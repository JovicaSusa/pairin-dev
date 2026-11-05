class AddLaunchEmailSentAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :launch_email_sent_at, :datetime
  end
end
