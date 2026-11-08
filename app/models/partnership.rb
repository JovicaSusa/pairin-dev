# Two people who agreed to work together on a partner search. Forming one closes
# the rest of the search: it goes Off, and every other application on it ends.
class Partnership < ApplicationRecord
  CLOSING_MESSAGE = "This partner search has found its partner, so this conversation has ended."

  belongs_to :offer
  belongs_to :pair_request
  belongs_to :ended_by, class_name: "User", optional: true
  has_many :check_ins, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :shared_links, dependent: :destroy

  GOAL_MAX_LENGTH = 500
  CHECK_IN_EVERY = 1.week

  validates :offer_id, :pair_request_id, uniqueness: true
  validates :goal, length: { maximum: GOAL_MAX_LENGTH }

  normalizes :goal, with: ->(goal) { goal.strip.presence }

  scope :involving, ->(user) {
    joins(:offer, :pair_request).where("offers.offerer_id = :id OR pair_requests.user_id = :id", id: user.id)
  }

  before_create :prefill_goal
  after_create :close_the_rest_of_the_search
  after_create_commit :tell_the_other_applicants

  def ended?
    ended_at? || offer.ended?
  end

  # Ending it ends the chat too, and the search stays Off. The record stays for
  # metrics. The other person hears only that it ended, even after a block, and
  # the reason stays private. Returns false if it had already ended.
  def end!(by:, reason: nil)
    ended = offer.with_lock do
      next false if ended_at?

      update_columns(ended_at: Time.current, ended_by_id: by.id, end_reason: reason.presence)
      offer.not_a_match!(by:)
      true
    end

    OfferMailer.with(offer:, ended_by: by).partnership_ended_email.deliver_later if ended
    ended
  end

  # What each person said they'd commit to: the search's commitment for the
  # poster, and the answer on the application for the applicant.
  def commitment_of(user)
    user == offer.poster ? pair_request.commitment_label : offer.how_long_label
  end

  def people
    [offer.offerer, offer.poster]
  end

  # How many whole weeks it has run: week 1's check-in goes out after 7 days.
  def weeks_completed
    ((Time.current - created_at) / CHECK_IN_EVERY).floor
  end

  def next_check_in_at
    created_at + (CHECK_IN_EVERY * (weeks_completed + 1))
  end

  # The latest finished week gets a check-in. Runs daily and is safe to repeat:
  # the unique index means each person gets one per week. A week missed because
  # the job didn't run isn't sent late.
  def send_due_check_ins
    return if ended? || weeks_completed.zero?

    people.each do |user|
      next if user.opted_out_of?("suggestions")

      check_in = check_ins.create!(user:, week: weeks_completed)
      CheckInMailer.with(check_in:).weekly_email.deliver_later
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      next
    end
  end

  # One entry per week so far. A week counts when at least one partner said Yes.
  def weeks_summary
    yes_weeks = check_ins.select(&:worked_together).map(&:week).to_set

    (1..weeks_completed).map { |week| { week:, worked_together: yes_weeks.include?(week) } }
  end

  private

  def prefill_goal
    self.goal = offer.goal.presence&.first(GOAL_MAX_LENGTH) || pair_request.subject.first(GOAL_MAX_LENGTH) if goal.blank?
  end

  # Each offer is re-read under its lock, so a first reply or "Not a match" that
  # lands at the same moment is seen, not overwritten.
  def close_the_rest_of_the_search
    pair_request.switch_off!

    @closed = []
    pair_request.offers.where.not(id: offer_id).where(ended_at: nil).find_each do |other|
      other.with_lock do
        next if other.ended_at?

        other.messages.create!(sender: nil, body: CLOSING_MESSAGE) if other.replied_at?
        other.update_columns(ended_at: Time.current, proposed_at: nil)
        @closed << other
      end
    end
  end

  # Anyone already told their application went quiet doesn't hear again.
  def tell_the_other_applicants
    return unless Rails.configuration.x.send_suggestion_emails

    @closed.reject { |closed| closed.expiry_notified_at? || closed.offerer.opted_out_of?("suggestions") }.each do |closed|
      OfferMailer.with(offer: closed).search_filled_email.deliver_later
      closed.update_columns(expiry_notified_at: Time.current)
    end
  end
end
