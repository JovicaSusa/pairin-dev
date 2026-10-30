class AddExpiryNotifiedAtToOffers < ActiveRecord::Migration[7.1]
  def change
    add_column :offers, :expiry_notified_at, :datetime
  end
end
