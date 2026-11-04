class AddGithubUrlToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :github_url, :string
  end
end
