# History only: the time an application or session used to book. Nothing creates these now.
class Period < ApplicationRecord
  belongs_to :periodable, polymorphic: true

  validates :start_at, :end_at, presence: true

  class << self
    def ransackable_attributes(auth_object=nil)
      ["start_at", "end_at"]
    end
  end
end
