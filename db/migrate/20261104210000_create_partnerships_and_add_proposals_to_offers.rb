class CreatePartnershipsAndAddProposalsToOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :partnerships do |t|
      t.references :offer, null: false, foreign_key: true, index: { unique: true }
      # One partnership per partner search.
      t.references :pair_request, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end

    add_column :offers, :proposed_at, :datetime
    add_reference :offers, :proposed_by, foreign_key: { to_table: :users }
    add_column :offers, :proposal_declined_at, :datetime
  end
end
