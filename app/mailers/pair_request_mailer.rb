class PairRequestMailer < ApplicationMailer
  def request_paused_email
    @pair_request = params[:pair_request]
    @resume_url = request_resumption_url(token: @pair_request.generate_token_for(:resume))

    mail(to: @pair_request.user.email, subject: "We paused your request \"#{@pair_request.subject}\"")
  end
end
