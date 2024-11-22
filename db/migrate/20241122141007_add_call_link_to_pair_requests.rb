class AddCallLinkToPairRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :pair_requests, :call_link, :text
  end
end
