class ChangeColumnNullForPairRequestsDuration < ActiveRecord::Migration[7.1]
  def change
    change_column_null :pair_requests, :duration, false
  end
end
