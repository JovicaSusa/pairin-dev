module Onboarding
  # The "about you" part of onboarding (#262): a name partners will see, and
  # optionally a level and a line about them. Saved before the partner-search
  # part, so skipping that keeps these.
  class Profile
    NAME_MAX = 60

    Result = Data.define(:errors) do
      def success? = errors.empty?
    end

    def self.call(...) = new(...).call

    # Only the given fields are checked and saved, so the one-time name page
    # can use this for the name alone.
    def initialize(user, params)
      @user = user
      @params = params
    end

    def call
      errors = {}
      errors[:name] = self.class.name_error(name) if @params.key?(:name) && self.class.name_error(name)
      errors[:level] = "Choose one of the levels" if level && !User::LEVELS.include?(level)
      return Result.new(errors:) if errors.any?

      changes = { name: }.compact
      changes[:level] = level if @params.key?(:level)
      changes[:about] = @params[:about].to_s.strip.presence if @params.key?(:about)
      # Only these fields: an older, half-filled profile mustn't block them here.
      @user.update_columns(changes) if changes.any?

      Result.new(errors: {})
    end

    def self.name_error(name)
      if name.blank? then "Enter a name"
      elsif name.length > NAME_MAX then "Keep it to #{NAME_MAX} characters"
      end
    end

    private

    def name = (@params[:name].to_s.squish if @params.key?(:name))
    def level = @params[:level].presence
  end
end
