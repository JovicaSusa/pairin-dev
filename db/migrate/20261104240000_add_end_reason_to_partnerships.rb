class AddEndReasonToPartnerships < ActiveRecord::Migration[7.1]
  def change
    add_column :partnerships, :end_reason, :text
  end
end
