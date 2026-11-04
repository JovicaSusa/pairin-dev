class CheckInMailerPreview < ActionMailer::Preview
  def weekly_email
    CheckInMailer.with(check_in: CheckIn.last).weekly_email
  end
end
