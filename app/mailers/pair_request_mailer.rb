class PairRequestMailer < ApplicationMailer
  def immediate_expired_email
    @pair_request = params[:pair_request]
    @user = params[:user]

    mail(to: @user.email, subject: "Nobody has joined your pair request yet")
  end
end
