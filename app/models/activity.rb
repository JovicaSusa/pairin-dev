class Activity < ApplicationRecord
  belongs_to :receiver, class_name: "User"

  validates :title, :content, presence: true
end
