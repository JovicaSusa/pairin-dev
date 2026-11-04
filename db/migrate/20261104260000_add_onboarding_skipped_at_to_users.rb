class AddOnboardingSkippedAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :onboarding_skipped_at, :datetime
  end
end
