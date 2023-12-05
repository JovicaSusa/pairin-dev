class AddPeriodIdAndAcceptedAtToOffers < ActiveRecord::Migration[7.1]
  def change
    add_column :offers, :period_id, :bigint, null: false
    add_column :offers, :accepted_at, :datetime
  end
end
