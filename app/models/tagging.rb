class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :taggable, polymorphic: true, inverse_of: :tagging

  accepts_nested_attributes_for :tag
end
