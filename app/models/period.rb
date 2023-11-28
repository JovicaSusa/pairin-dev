class Period < ApplicationRecord
  belongs_to :periodable, polymorphic: true

  validates :start_at, presence: true
end
