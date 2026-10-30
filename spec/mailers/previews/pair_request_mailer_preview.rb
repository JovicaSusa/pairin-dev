# Preview all emails at http://localhost:3000/rails/mailers/pair_request_mailer
class PairRequestMailerPreview < ActionMailer::Preview
  def request_paused_email
    PairRequestMailer.with(pair_request: PairRequest.last).request_paused_email
  end
end
