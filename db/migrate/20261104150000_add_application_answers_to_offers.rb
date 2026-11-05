class AddApplicationAnswersToOffers < ActiveRecord::Migration[7.1]
  def change
    add_column :offers, :goal, :text
    add_column :offers, :how_often, :string
    add_column :offers, :how_long, :string
  end
end
