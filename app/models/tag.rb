class Tag < ApplicationRecord
  has_many :taggings

  validates :name, presence: true, uniqueness: true

  class << self
    def ransackable_attributes(auth_object=nil)
      ["name"]
    end
  end
end
