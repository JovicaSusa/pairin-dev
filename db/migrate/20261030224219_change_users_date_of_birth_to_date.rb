# A birthday is a calendar date. As a datetime, "2000-01-15" entered in Tokyo
# was parsed in the user's zone and stored as 2000-01-14 15:00 UTC. So first
# shift each value to the user's own wall-clock time (UTC if Postgres doesn't
# know their zone), then drop the time part.
class ChangeUsersDateOfBirthToDate < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE users
      SET date_of_birth = date_of_birth AT TIME ZONE 'UTC'
        AT TIME ZONE (CASE WHEN timezone IN (SELECT name FROM pg_timezone_names) THEN timezone ELSE 'UTC' END)
      WHERE date_of_birth IS NOT NULL
    SQL

    change_column :users, :date_of_birth, :date
  end

  def down
    change_column :users, :date_of_birth, :datetime
  end
end
