# No-login unsubscribe, one category at a time, reached from an email's footer.
# GET only shows it, because email scanners open every link. POST unsubscribes,
# which is also what mail apps send for List-Unsubscribe-Post, so it can't carry
# a CSRF token. The signed token in the URL is what authorises it.
class UnsubscribesController < ApplicationController
  include NoLoginTokenPage

  skip_forgery_protection only: :create

  before_action :set_user

  def show
  end

  def create
    @user.opt_out_of!(params[:category])

    redirect_to unsubscribe_path(category: params[:category], token: params[:token])
  end

  private

  def set_user
    @user = User.find_by_unsubscribe_token(params[:category], params[:token])

    render :invalid, status: :not_found unless @user
  end
end
