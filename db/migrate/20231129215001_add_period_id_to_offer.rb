class AddPeriodIdToOffer < ActiveRecord::Migration[7.1]
  def change
    add_column :offers, :period_id, :bigint, null: false
  end
end
