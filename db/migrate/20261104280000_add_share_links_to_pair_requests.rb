class AddShareLinksToPairRequests < ActiveRecord::Migration[7.1]
  def up
    add_column :pair_requests, :share_token, :string
    PairRequest.reset_column_information
    PairRequest.unscoped.find_each { |search| search.update_columns(share_token: SecureRandom.base58(24)) }
    change_column_null :pair_requests, :share_token, false
    add_index :pair_requests, :share_token, unique: true

    # Which search brought someone to sign up, kept for the funnel.
    add_reference :users, :signup_pair_request, foreign_key: { to_table: :pair_requests, on_delete: :nullify }
    add_column :users, :signup_search_taken_at, :datetime

    add_column :offers, :via_share_link, :boolean, default: false, null: false
  end

  def down
    remove_column :offers, :via_share_link
    remove_column :users, :signup_search_taken_at
    remove_reference :users, :signup_pair_request, foreign_key: { to_table: :pair_requests }
    remove_column :pair_requests, :share_token
  end
end
