class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :taggable, polymorphic: true

  accepts_nested_attributes_for :tag

  def tag_attributes=(attributes)
    name = attributes[:name].to_s.strip.downcase
    return if name.blank?

    self.tag = Tag.find_or_create_by!(name: name)
  end
end
