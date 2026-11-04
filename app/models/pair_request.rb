class PairRequest < ApplicationRecord
  include ActivityGeneratable

  # The random part of the shareable link, so searches can't be found by guessing.
  has_secure_token :share_token, length: 24

  belongs_to :user
  has_many :offers, dependent: :destroy
  has_one :partnership, dependent: :destroy
  has_one :accepted_offer, -> { accepted }, class_name: "Offer"
  # History only: requests used to own their time slots.
  has_many :periods, as: :periodable, dependent: :destroy, inverse_of: :periodable
  has_many :sessions, as: :sessionable
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  COMMITMENTS = {
    "few_weeks" => "A few weeks",
    "one_to_three_months" => "1–3 months",
    "open_ended" => "Open-ended"
  }.freeze

  enum :commitment, COMMITMENTS.keys.index_with(&:itself), validate: true

  validates :description, :subject, presence: true

  scope :switched_on, -> { where(paused_at: nil) }
  # Only searches from the viewer's own age group, and nobody they've blocked or been blocked by.
  scope :visible_to, ->(user) { where(user_id: user.same_age_group.select(:id)).where.not(user_id: user.blocked_user_ids) }

  # Signed token for the no-login "Turn it back on" link in the paused email.
  generates_token_for :resume, expires_in: 30.days
  # And for the "Pause this search" link in the emails about it.
  generates_token_for :pause, expires_in: 30.days

  accepts_nested_attributes_for :taggings,
    reject_if: ->(attrs) { attrs["tag_attributes"].blank? || attrs["tag_attributes"]["name"].blank? },
    allow_destroy: true
  accepts_nested_attributes_for :sessions, reject_if: :new_record?

  class << self
    def ransackable_associations(auth_object=nil)
      ["tags", "user"]
    end

    def ransackable_attributes(auth_object=nil)
      ["commitment"]
    end
  end

  def commitment_label
    COMMITMENTS.fetch(commitment)
  end

  # Only adults have a public page, whatever the state of the search. Someone
  # whose age we don't know yet can't be seen by anyone, so they don't either.
  def shareable?
    user.adult?
  end

  # A signed-in person outside the poster's age group, or blocked either way,
  # can't see this search anywhere, including through its link.
  def visible_through_link_to?(viewer)
    return true if viewer.nil? || viewer == user

    viewer.same_age_group?(user) && !viewer.blocked_with?(user)
  end

  def taking_applications?
    partnership.nil? && !paused?
  end

  # Off requests are hidden from others and can't receive offers.
  def paused?
    paused_at?
  end

  # Toggling On/Off only touches paused_at, so it works even for older
  # requests that wouldn't pass today's validations.
  def switch_off!
    update_columns(paused_at: Time.current, updated_at: Time.current)
  end

  # A search that has found its partner stays Off. Returns whether it's On.
  def switch_on!
    return false if partnership

    update_columns(paused_at: nil, updated_at: Time.current)
  end

  def has_accepted_offer?
    offers.accepted.exists?
  end
end
