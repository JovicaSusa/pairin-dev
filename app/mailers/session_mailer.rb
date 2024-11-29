class SessionMailer < ApplicationMailer
  def session_scheduled_email
    @session = params[:session]
    @participant = params[:participant]

    mail(to: @participant.email, subject: "Your pair programming session has been scheduled")
  end
end
