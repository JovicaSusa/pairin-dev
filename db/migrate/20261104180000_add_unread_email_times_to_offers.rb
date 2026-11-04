class AddUnreadEmailTimesToOffers < ActiveRecord::Migration[7.1]
  def change
    add_column :offers, :poster_emailed_at, :datetime
    add_column :offers, :offerer_emailed_at, :datetime
  end
end
