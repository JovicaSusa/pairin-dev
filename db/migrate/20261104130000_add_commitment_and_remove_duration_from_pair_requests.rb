class AddCommitmentAndRemoveDurationFromPairRequests < ActiveRecord::Migration[7.1]
  def up
    add_column :pair_requests, :commitment, :string, null: false, default: "one_to_three_months"
    remove_column :pair_requests, :duration
  end

  def down
    add_column :pair_requests, :duration, :integer, null: false, default: 60
    change_column_default :pair_requests, :duration, from: 60, to: nil
    remove_column :pair_requests, :commitment
  end
end
