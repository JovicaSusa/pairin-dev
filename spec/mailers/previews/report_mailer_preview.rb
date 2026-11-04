class ReportMailerPreview < ActionMailer::Preview
  def chat_report
    offer = Offer.last
    ReportMailer.with(offer:, reporter: offer.poster, reason: "They were rude to me.").chat_report
  end
end
