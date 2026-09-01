# Preview all emails at http://localhost:3000/rails/mailers/pair_request
class PairRequestMailerPreview < ActionMailer::Preview
  def immediate_expired_email
    PairRequestMailer.with(pair_request: PairRequest.first, user: PairRequest.first.user).immediate_expired_email
  end
end
