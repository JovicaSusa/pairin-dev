class AddDurationToPairRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :pair_requests, :duration, :integer
  end
end
