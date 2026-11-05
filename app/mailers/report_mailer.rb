# Goes to the founder, who acts by hand. The person reported is never told.
class ReportMailer < ApplicationMailer
  RECENT_MESSAGES = 20

  def chat_report
    @offer = params[:offer]
    @reporter = params[:reporter]
    @reported = @offer.other_person(@reporter)
    @reason = params[:reason]
    @messages = @offer.messages.includes(:sender).order(created_at: :desc, id: :desc).limit(RECENT_MESSAGES).to_a.reverse

    mail(to: Rails.configuration.x.reports_email, subject: "Report: conversation ##{@offer.id}")
  end
end
