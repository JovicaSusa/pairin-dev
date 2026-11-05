class AddReadTimesToOffers < ActiveRecord::Migration[7.1]
  def up
    add_column :offers, :poster_read_at, :datetime
    add_column :offers, :offerer_read_at, :datetime

    # Everything before this counts as read, so nobody starts with a pile of unread.
    execute "UPDATE offers SET poster_read_at = now(), offerer_read_at = now()"
  end

  def down
    remove_column :offers, :poster_read_at
    remove_column :offers, :offerer_read_at
  end
end
