class LaunchMailerPreview < ActionMailer::Preview
  def announcement
    LaunchMailer.with(user: User.first).announcement
  end
end
