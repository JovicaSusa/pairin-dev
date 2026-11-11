require "rails_helper"
require "rake"

RSpec.describe Release::SendLaunchEmail, type: :unit do
  subject(:task) { described_class.new }

  def email_to(user) = have_enqueued_mail(LaunchMailer, :announcement).with(params: { user: }, args: [])

  describe "who gets it" do
    let!(:confirmed) { create(:user) }
    let!(:unconfirmed) { create(:user, confirmed_at: nil) }
    let!(:opted_out) { create(:user, announcements_opted_out_at: 1.day.ago) }
    let!(:suspended) { create(:user, suspended_at: 1.day.ago) }
    let!(:no_date_of_birth) { create(:user).tap { |u| u.update_columns(date_of_birth: nil) } }
    let!(:suggestions_only_opt_out) { create(:user, suggestions_opted_out_at: 1.day.ago) }

    it "is confirmed, active users who haven't opted out of announcements" do
      expect(task.recipients).to contain_exactly(confirmed, no_date_of_birth, suggestions_only_opt_out)
    end

    it "sends each of them one, and records it" do
      expect { task.send_all }.to have_enqueued_mail(LaunchMailer, :announcement).exactly(3).times

      expect(confirmed.reload.launch_email_sent_at).to be_present
      expect(task.sent_count).to eq(3)
    end

    it "sends nothing the second time" do
      task.send_all

      expect { task.send_all }.not_to have_enqueued_mail(LaunchMailer, :announcement)
    end

    it "only reaches someone it missed when run again" do
      confirmed.update_columns(launch_email_sent_at: 1.day.ago)

      expect { task.send_all }.to have_enqueued_mail(LaunchMailer, :announcement).twice
    end
  end

  describe "sending in batches" do
    let!(:users) { create_list(:user, 3) }

    it "sends only as many as the limit, and marks only those" do
      expect { task.send_all(limit: 2) }.to have_enqueued_mail(LaunchMailer, :announcement).twice

      expect(task.sent_count).to eq(2)
      expect(task.recipients.count).to eq(1)
    end

    it "reaches the rest on the next run, without repeating anyone" do
      task.send_all(limit: 2)

      expect { task.send_all(limit: 2) }.to have_enqueued_mail(LaunchMailer, :announcement).once
      expect(task.recipients).to be_empty
    end
  end

  describe "the email" do
    let(:user) { create(:user, name: "Maya Jones", email: "maya@example.com") }
    let(:mail) { LaunchMailer.with(user:).announcement }
    let(:html) { mail.html_part.body.encoded }
    let(:text) { mail.text_part.body.encoded }

    it "comes from Pairin, with replies to you" do
      expect(mail.to).to eq(["maya@example.com"])
      expect(mail.reply_to).to eq(["hello@pairin.dev"])
      expect(mail.subject).to eq("Pairin works differently now")
    end

    it "invites replies, in both versions" do
      [html, text].each { |body| expect(body.gsub(/\s+/, " ")).to include("just reply. We'd like to hear from you, and we read every reply.") }
    end

    it "greets by first name, or without one" do
      expect(text).to start_with("Hi Maya,")

      user.update_columns(name: nil)
      expect(LaunchMailer.with(user:).announcement.text_part.body.encoded).to start_with("Hi,")
    end

    it "has a one-click unsubscribe for announcements, in the headers and the footer" do
      value = mail.header["List-Unsubscribe"].value

      expect(value).to include("/unsubscribe/announcements/")
      expect(mail.header["List-Unsubscribe-Post"].value).to eq("List-Unsubscribe=One-Click")
      expect(html).to include("Unsubscribe from announcements")
      expect(text).to include("/unsubscribe/announcements/")
      expect(User.find_by_unsubscribe_token("announcements", value[%r{/announcements/([^>]+)>}, 1])).to eq(user)
    end

    it "offers someone with no search a way to post one" do
      expect(text).to include("posting a search takes about a minute")
      expect(text).to include("/onboarding")
    end

    it "names one switched-off search, and links to their searches" do
      create(:pair_request, user:, subject: "Learn Rust", paused_at: 1.day.ago)

      expect(text).to include('your old search, "Learn Rust"')
      expect(text).to include("/users/pair_requests")
      expect(text).not_to include("/onboarding")
    end

    it "talks about several switched-off searches together" do
      create_list(:pair_request, 2, user:, paused_at: 1.day.ago)

      expect(text).to include("your old searches")
    end

    it "doesn't claim to have switched off a search that's on" do
      create(:pair_request, user:)

      expect(text).to include("Your search is still on")
      expect(text).not_to include("switched off")
    end

    it "mentions the first-sign-in steps only to those who'll see them" do
      expect(text).not_to include("the first time you sign in")

      user.update_columns(date_of_birth: nil)
      expect(LaunchMailer.with(user:).announcement.text_part.body.encoded).to include("we'll ask for your date of birth.")

      user.update_columns(name: nil)
      expect(LaunchMailer.with(user:).announcement.text_part.body.encoded).to include("we'll ask for your name and date of birth.")

      user.update_columns(date_of_birth: Date.new(1990, 1, 1))
      expect(LaunchMailer.with(user:).announcement.text_part.body.encoded).to include("we'll ask for your name.")
    end

    it "says Pairin is built by two developers" do
      [html, text].each { |body| expect(body).to include("Pairin is built by two developers") }
      expect(text).not_to include("on my own")
    end

    it "speaks as we throughout, and introduces the first-sign-in step" do
      user.update_columns(date_of_birth: nil)
      create(:pair_request, user:, paused_at: 1.day.ago)
      mail = LaunchMailer.with(user:).announcement
      [mail.text_part.body.encoded, mail.html_part.body.encoded].each do |body|
        expect(body).not_to match(/\bI('d|'ve| read)\b|on me\b/)
        expect(body).to include("That's on us", "So we've changed it", "We've switched off your old search")
        expect(body).to include("Quick note: the first time you sign in, we'll ask for your date of birth.")
      end
    end

    it "escapes a search's subject in the HTML" do
      create(:pair_request, user:, subject: "<b>Rust</b>", paused_at: 1.day.ago)

      expect(html).to include("&lt;b&gt;Rust")
    end
  end

  describe "the rake task" do
    let(:rake_task) do
      Rails.application.load_tasks unless Rake::Task.task_defined?("release:send_launch_email")
      Rake::Task["release:send_launch_email"].tap(&:reenable)
    end

    def with_env(apply: nil, test_email: nil, limit: nil)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("APPLY").and_return(apply)
      allow(ENV).to receive(:[]).with("TEST_EMAIL").and_return(test_email)
      allow(ENV).to receive(:[]).with("LIMIT").and_return(limit)
    end

    let!(:user) { create(:user, email: "someone@example.com") }

    it "only reports by default" do
      with_env

      expect { expect { rake_task.invoke }.to output(/Will receive it:\s+1.*Nothing sent/m).to_stdout }
        .not_to have_enqueued_mail(LaunchMailer, :announcement)
      expect(user.reload.launch_email_sent_at).to be_nil
    end

    it "sends with APPLY=1" do
      with_env(apply: "1")

      expect { expect { rake_task.invoke }.to output(/Sent to so far: 1/).to_stdout }
        .to have_enqueued_mail(LaunchMailer, :announcement).once
    end

    it "sends only a batch with LIMIT, and says how many are left" do
      create_list(:user, 2)
      with_env(apply: "1", limit: "2")

      expect { expect { rake_task.invoke }.to output(/Sent to so far: 2.*Still to send: 1/m).to_stdout }
        .to have_enqueued_mail(LaunchMailer, :announcement).twice
    end

    it "reports the batch size without sending when LIMIT comes without APPLY" do
      create_list(:user, 2)
      with_env(limit: "2")

      expect { expect { rake_task.invoke }.to output(/This batch:\s+2.*Nothing sent/m).to_stdout }
        .not_to have_enqueued_mail(LaunchMailer, :announcement)
    end

    %w[0 -5 abc 1.5].each do |bad|
      it "refuses LIMIT=#{bad} and sends nothing" do
        with_env(apply: "1", limit: bad)

        expect { expect { rake_task.invoke }.to raise_error(SystemExit).and output(/LIMIT/).to_stderr }
          .not_to have_enqueued_mail(LaunchMailer, :announcement)
      end
    end

    it "sends a test copy to one person, without marking them" do
      other = create(:user)
      with_env(test_email: "someone@example.com")

      expect { expect { rake_task.invoke }.to output(/test copy/).to_stdout }
        .to email_to(user).once

      expect(user.reload.launch_email_sent_at).to be_nil
      expect(other.reload.launch_email_sent_at).to be_nil
    end

    it "refuses an unknown test address" do
      with_env(test_email: "nobody@example.com")

      expect { rake_task.invoke }.to raise_error(SystemExit).and output(/No user/).to_stderr
    end
  end
end
