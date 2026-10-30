class AddPausedAtToPairRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :pair_requests, :paused_at, :datetime
  end
end
