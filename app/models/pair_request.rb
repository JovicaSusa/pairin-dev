class PairRequest < ApplicationRecord
  include ActivityGeneratable

  belongs_to :user
  has_many :offers, dependent: nil # TODO: Reconsider
  has_many :periods, as: :periodable, dependent: :destroy
  has_many :sessions, as: :sessionable
  has_many :taggings, as: :taggable
  has_many :tags, through: :taggings

  validates :description, :subject, :duration, presence: true
  validates :duration, numericality: { greater_than: 0 }

  scope :active, -> { joins(:periods).merge(Period.future) }

  accepts_nested_attributes_for :periods, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :taggings, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :sessions, reject_if: :new_record?

  class << self
    def ransackable_associations(auth_object=nil)
      ["tags", "user", "periods"]
    end

    def ransackable_attributes(auth_object=nil)
      ["duration"]
    end
  end

  def has_accepted_offer?
    offers.accepted.exists?
  end
end
