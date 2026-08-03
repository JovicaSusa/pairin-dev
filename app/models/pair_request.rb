class PairRequest < ApplicationRecord
  include ActivityGeneratable

  MODES = %w(immediate scheduled).freeze
  PLATFORMS = %w(zoom google_meet discord other).freeze
  WAIT_MINUTES_OPTIONS = [15, 30, 60, 120].freeze

  belongs_to :user
  has_many :offers, dependent: nil # TODO: Reconsider
  has_one :accepted_offer, -> { accepted }, class_name: "Offer"
  has_many :periods, as: :periodable, dependent: :destroy, inverse_of: :periodable
  has_many :sessions, as: :sessionable
  has_many :taggings, as: :taggable
  has_many :tags, through: :taggings

  validates :description, :subject, :duration, presence: true
  validates :duration, numericality: { greater_than: 0 }
  validates :mode, inclusion: { in: MODES }
  validates :wait_minutes, inclusion: { in: WAIT_MINUTES_OPTIONS }, allow_nil: true
  validates :platform, inclusion: { in: PLATFORMS }, allow_blank: true

  scope :active, -> { joins(:periods).merge(Period.future) }
  scope :scheduled_active, -> { active.where(mode: "scheduled") }
  scope :live_now, lambda {
    joins(:periods)
      .where(mode: "immediate")
      .where.not(id: Offer.accepted.select(:pair_request_id))
      .where("periods.start_at + (COALESCE(pair_requests.wait_minutes, 0) * interval '1 minute') > ?", Time.current)
  }

  accepts_nested_attributes_for :periods, allow_destroy: true
  accepts_nested_attributes_for :taggings,
    reject_if: ->(attrs) { attrs["tag_attributes"].blank? || attrs["tag_attributes"]["name"].blank? },
    allow_destroy: true
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

  def immediate?
    mode == "immediate"
  end
end
