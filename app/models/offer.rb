class Offer < ApplicationRecord
  include ActivityGeneratable

  belongs_to :offerer, class_name: "User"
  belongs_to :pair_request
  belongs_to :ended_by, class_name: "User", optional: true
  has_many :messages, dependent: :destroy
  # History only: applications used to book a time. New ones have no period.
  has_one :period, as: :periodable, dependent: :destroy, inverse_of: :periodable, autosave: true

  HOW_OFTEN = {
    "once_a_week" => "About once a week",
    "twice_a_week" => "Twice a week",
    "more" => "More than twice a week"
  }.freeze

  # Old applications have no answers, so these stay optional on them.
  enum :how_often, HOW_OFTEN.keys.index_with(&:itself), prefix: true, validate: { allow_nil: true }
  enum :how_long, PairRequest::COMMITMENTS.keys.index_with(&:itself), prefix: true, validate: { allow_nil: true }

  validates :message, presence: true, length: { maximum: Message::MAX_LENGTH }
  validates :goal, :how_often, :how_long, presence: true, on: :create
  validate :offerer_has_a_level, on: :create
  validates :pair_request_id, uniqueness: { scope: :offerer_id }

  UNREAD_EMAIL_AFTER = 15.minutes
  REMIND_AFTER = 24.hours
  ANSWER_WITHIN = 72.hours

  # The application's message starts its thread.
  after_create { messages.create!(sender: offerer, body: message) }

  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :involving, ->(user) { joins(:pair_request).where("offers.offerer_id = :id OR pair_requests.user_id = :id", id: user.id) }

  def accepted?
    accepted_at?
  end

  # The clock on an application runs until the poster replies or either person
  # ends it. Old applications accepted the old way count as answered too.
  def unanswered?
    !replied_at? && !ended? && !accepted?
  end

  # The poster has gone past the deadline, so a reply now is a late one.
  def overdue?
    unanswered? && expires_at <= Time.current
  end

  def poster
    pair_request.user
  end

  def other_person(user)
    user == offerer ? poster : offerer
  end

  # The poster's first reply opens the chat. It isn't a commitment.
  def chat_open?
    replied_at? && !ended?
  end

  def ended?
    ended_at?
  end

  # The applicant has said their piece until the poster replies.
  def can_message?(user)
    return false if ended?

    user == poster || (user == offerer && replied_at?)
  end

  # Under a lock, so two first replies, or a reply and "Not a match", can't cross.
  # Returns the message, unsaved with errors if the body was refused, or nil
  # if this person can't write here.
  def post_message(sender, body)
    with_lock do
      next unless can_message?(sender)

      messages.create(sender:, body:).tap do |message|
        update_columns(replied_at: message.created_at) if message.persisted? && sender == poster && !replied_at?
      end
    end
  end

  # Returns false if it had already ended.
  def not_a_match!(by:, reason: nil)
    with_lock do
      next false if ended?

      update_columns(ended_at: Time.current, ended_by_id: by.id, end_reason: reason.presence)
      true
    end
  end

  def conversation_status_for(user)
    return "Ended" if ended?
    return "Talking" if replied_at?

    user == poster ? "Reply" : "Sent"
  end

  def mark_read_by!(user)
    update_columns(read_column_for(user) => Time.current)
  end

  def unread_messages_for(user)
    read_at = public_send(read_column_for(user))
    unread = messages.where.not(sender: user)

    read_at ? unread.where("messages.created_at > ?", read_at) : unread
  end

  # One email per stretch of unread: none until they've read since the last one,
  # and not before the oldest unread message has waited long enough.
  def unread_email_due_for?(user)
    return false if ended?

    emailed_at = public_send(emailed_column_for(user))
    read_at = public_send(read_column_for(user))
    return false if emailed_at && (read_at.nil? || emailed_at > read_at)

    oldest_unread = unread_messages_for(user).minimum(:created_at)
    oldest_unread.present? && oldest_unread <= UNREAD_EMAIL_AFTER.ago
  end

  def mark_unread_emailed_to!(user)
    update_columns(emailed_column_for(user) => Time.current)
  end

  def how_often_label
    HOW_OFTEN[how_often]
  end

  def how_long_label
    PairRequest::COMMITMENTS[how_long]
  end

  # What the application form offers, for its dropdowns.
  def self.form_options
    to_options = ->(labels) { labels.map { |value, label| { value:, label: } } }

    {
      howOften: to_options.call(HOW_OFTEN),
      howLong: to_options.call(PairRequest::COMMITMENTS),
      levels: to_options.call(User::LEVELS.index_with(&:titleize))
    }
  end

  def reminder_at
    created_at + REMIND_AFTER
  end

  def expires_at
    created_at + ANSWER_WITHIN
  end

  def offerer_display_name
    offerer.display_name
  end

  def status
    if accepted?
      "ACCEPTED"
    elsif pair_request.has_accepted_offer?
      "ACCEPTED OTHER"
    else
      "PENDING"
    end
  end

  private

  def read_column_for(user)
    user == offerer ? :offerer_read_at : :poster_read_at
  end

  def emailed_column_for(user)
    user == offerer ? :offerer_emailed_at : :poster_emailed_at
  end

  # Their level comes from their profile. The form asks once when it's blank.
  def offerer_has_a_level
    errors.add(:level, "can't be blank") unless User::LEVELS.include?(offerer&.level)
  end
end
