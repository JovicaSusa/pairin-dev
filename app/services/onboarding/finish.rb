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

      pair_request = User.transaction do
        save_profile
        save_weekly_hours
        post_search
      end

      Result.new(pair_request:, errors: {})
    rescue ActiveRecord::RecordInvalid => e
      Result.new(pair_request: nil, errors: { base: e.record.errors.full_messages.first })
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.cause.is_a?(PG::ExclusionViolation)

      Result.new(pair_request: nil, errors: { windows: "Those hours overlap hours you've already added" })
    end

    private

    def required_answers_missing
      errors = {}
      errors[:topics] = "Pick at least one topic" if topics.empty?
      errors[:level] = "Choose where you're at" unless User::LEVELS.include?(@params[:level])
      errors
    end

    def topics
      @topics ||= Array(@params[:topics]).map { |name| name.to_s.strip }.reject(&:empty?).uniq(&:downcase)
    end

    def goal
      @params[:goal].to_s.strip
    end

    # Only these fields: an older, half-filled profile mustn't block a first search.
    def save_profile
      changes = { level: @params[:level] }
      changes[:timezone] = @params[:timezone] if User::TIMEZONES.include?(@params[:timezone])
      @user.update_columns(changes)
    end

    def save_weekly_hours
      Array(@params[:windows]).each { |window| @user.availability_windows.create!(window) }
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
