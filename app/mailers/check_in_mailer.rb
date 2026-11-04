class CheckInMailer < ApplicationMailer
  def weekly_email
    @check_in = params[:check_in]
    @partner = @check_in.partnership.offer.other_person(@check_in.user)
    token = @check_in.generate_token_for(:answer)
    @yes_url = check_in_url(token:, answer: "yes")
    @no_url = check_in_url(token:, answer: "no")

    mail(to: @check_in.user.email, subject: "Did you and #{@partner.display_name} work together this week?")
  end
end
