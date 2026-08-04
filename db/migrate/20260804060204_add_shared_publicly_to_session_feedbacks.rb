class AddSharedPubliclyToSessionFeedbacks < ActiveRecord::Migration[7.1]
  def change
    add_column :session_feedbacks, :shared_publicly, :boolean, default: false, null: false
  end
end
