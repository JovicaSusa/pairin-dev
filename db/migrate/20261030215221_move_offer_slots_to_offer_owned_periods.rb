# Requests no longer own time slots: each offer keeps its own Period for the
# slot it booked. Existing offers get a copy of the request slot they pointed at.
class MoveOfferSlotsToOfferOwnedPeriods < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      INSERT INTO periods (periodable_type, periodable_id, start_at, end_at, created_at, updated_at)
      SELECT 'Offer', offers.id, periods.start_at, periods.end_at, NOW(), NOW()
      FROM offers
      JOIN periods ON periods.id = offers.period_id
    SQL

    remove_column :offers, :period_id
  end

  def down
    add_column :offers, :period_id, :bigint

    execute <<~SQL
      UPDATE offers SET period_id = periods.id
      FROM periods
      WHERE periods.periodable_type = 'Offer' AND periods.periodable_id = offers.id
    SQL

    change_column_null :offers, :period_id, false
  end
end
