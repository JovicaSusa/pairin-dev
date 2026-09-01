class SessionMailer < ApplicationMailer
  def session_scheduled_email
    @session = params[:session]
    @participant = params[:participant]

    mail(to: @participant.email, subject: "Your pair programming session has been scheduled")
  end

  def retro_nag_email
    @session = params[:session]
    @participant = params[:participant]

    mail(to: @participant.email, subject: "Don't forget to leave feedback for your last session")
  end
end
