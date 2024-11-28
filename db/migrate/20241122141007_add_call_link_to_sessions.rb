class AddCallLinkToSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :sessions, :call_link, :text
  end
end
