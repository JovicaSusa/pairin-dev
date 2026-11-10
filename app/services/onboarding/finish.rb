module Onboarding
  # One form's worth of first-run answers: the profile fields, any weekly hours
  # and an On partner search, saved together or not at all.
  class Finish
    Result = Data.define(:pair_request, :errors) do
      def success? = errors.empty?
    end

    def self.call(...) = new(...).call

    def initialize(user, params)
      @user = user
      @params = params
    end

    def call
      errors = required_answers_missing
      return Result.new(pair_request: nil, errors:) if errors.any?

      # The lock means a double click can't post two searches: the second one
      # waits, then finds the first and stops there.
      pair_request = @user.with_lock do
        next @user.pair_requests.first if @user.pair_requests.exists?

        save_timezone
        save_weekly_hours
        post_search
      end

      Result.new(pair_request:, errors: {})
    rescue ActiveRecord::RecordInvalid => e
      Result.new(pair_request: nil, errors: { base: e.record.errors.full_messages.first })
    rescue ActiveRecord::RecordNotUnique
      # Someone else created the same new topic at this moment. It exists now, so try once more.
      raise if @retried

      @retried = true
      retry
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.cause.is_a?(PG::ExclusionViolation)

      Result.new(pair_request: nil, errors: { windows: "Those hours overlap hours you've already added" })
    end

    private

    def required_answers_missing
      errors = {}
      errors[:topics] = "Pick at least one topic" if topics.empty?
      errors
    end

    def topics
      @topics ||= Array(@params[:topics]).map { |name| name.to_s.strip }.reject(&:empty?).uniq(&:downcase)
    end

    def goal
      @params[:goal].to_s.strip
    end

    # Only the timezone: the profile part saved the rest, and an older,
    # half-filled profile mustn't block a first search.
    def save_timezone
      @user.update_columns(timezone: @params[:timezone]) if User::TIMEZONES.include?(@params[:timezone])
    end

    # Hours saved earlier stay as they are, and anything that overlaps them is
    # already covered, so it shouldn't stop them finishing.
    def save_weekly_hours
      saved = @user.availability_windows.to_a

      Array(@params[:windows]).each do |window|
        next if saved.any? { |existing| overlaps?(existing, window) }

        @user.availability_windows.create!(window)
      end
    end

    def overlaps?(existing, window)
      existing.weekday == window[:weekday].to_i &&
        existing.start_minute < window[:end_minute].to_i &&
        window[:start_minute].to_i < existing.end_minute
    end

    def post_search
      @user.pair_requests.create!(
        subject: "Learning partner for #{topics.to_sentence}".first(255),
        description: goal.presence || "Looking for a partner to learn #{topics.to_sentence} with.",
        commitment: @params[:commitment].presence || PairRequest.column_defaults["commitment"],
        taggings_attributes: topics.map { |name| { tag_attributes: { name: } } }
      )
    end
  end
end
