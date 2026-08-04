class AddCancelledAtToPairRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :pair_requests, :cancelled_at, :datetime
  end
end
