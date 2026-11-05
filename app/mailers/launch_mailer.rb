# The one email to existing users at the soft launch, in the founder's voice.
class LaunchMailer < ApplicationMailer
  include Unsubscribable

  layout false

  def announcement
    @user = params[:user]
    @paused_searches = @user.pair_requests.where.not(paused_at: nil).order(created_at: :desc).to_a
    @has_on_search = @user.pair_requests.switched_on.exists?
    @action_url = @paused_searches.any? || @has_on_search ? users_pair_requests_url : onboarding_url
    allow_unsubscribe(@user, "announcements")

    mail(to: @user.email, reply_to: "hello@pairin.dev", subject: "Pairin works differently now")
  end
end
