# Backs AvailabilityWindow#doesnt_overlap_another_window, which two concurrent
# requests can both pass. int4range is half-open, so touching windows still fit.
class AddNoOverlapConstraintToAvailabilityWindows < ActiveRecord::Migration[7.1]
  def change
    enable_extension "btree_gist"

    add_exclusion_constraint :availability_windows,
      "user_id WITH =, weekday WITH =, int4range(start_minute, end_minute) WITH &&",
      using: :gist, name: "availability_windows_no_overlap"
  end
end
