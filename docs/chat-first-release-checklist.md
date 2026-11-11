# Chat-first release checklist

Merging `chat-first` to `main` deploys it, so do these in order.

## Before merging

- [ ] Run the checks in `docs/qa-plans/chat-first-release-qa-plan.md` that need a person.
- [ ] SPF and DMARC are in place (#153), and `hello@pairin.dev` and `reports@pairin.dev` reach you.
- [ ] Mailjet click tracking is still off.
- [ ] The homepage no longer advertises "Go live" and instant matching.
- [ ] Terms and privacy no longer mention retros and Session Summaries, and their "Last updated" date is the day you merge.
- [x] The launch email (#152) is written and approved. *(Final copy approved 2026-11-11 in #268: speaks as "we", a "Quick note" for the first-sign-in steps, signed "Jovica, for the Pairin team".)*
- [ ] Replace the Honeybadger API key, because the old one is public in this repo's history. Do this just before merging, because production stops reporting errors from the moment the old key is revoked until the deploy finishes. Generate a new key in Honeybadger, then run this and paste it when asked:

  ```
  gh secret set HONEYBADGER_API_KEY
  ```

  Also add `HONEYBADGER_API_KEY` to your shell's environment if you run `kamal` commands locally.
- [ ] Back up the database:

  ```
  bundle exec kamal accessory exec db --reuse --quiet 'pg_dump -U pairin pairin_production' > pairin-before-chat-first.sql
  ```

  This command hasn't been tried yet, so open the file and check it's a real SQL dump, with no log lines at the top, and keep it somewhere safe. Hetzner's daily backup is a second copy, not a replacement, because it can be up to a day old.
- [ ] Check what's on production now:

  ```
  bundle exec kamal app exec --reuse --roles=web 'bin/rails runner "puts [PairRequest.where(paused_at: nil).count, Offer.where(accepted_at: nil).count, Session.count].inspect"'
  ```

  On 2026-10-30 this was 19 searches, 8 pending applications and 0 sessions, with none of the times ahead. If there are real upcoming sessions now, stop and decide what to do with them.

## Deploying

- [ ] Note the time, in UTC.
- [ ] Merge `chat-first` to `main`, and wait for the deploy to finish. This turns on `SEND_SUGGESTION_EMAILS`.
- [ ] Straight away, see what the cleanup would do, with `BEFORE` set to the time you noted:

  ```
  bundle exec kamal app exec --reuse --roles=web 'bin/rails release:close_old_data BEFORE=2026-12-01T10:00:00Z'
  ```

  Between the deploy and this step, an old queued job could still send a polite email, so don't leave a gap.
- [ ] If the numbers look right, run it for real:

  ```
  bundle exec kamal app exec --reuse --roles=web 'bin/rails release:close_old_data BEFORE=2026-12-01T10:00:00Z APPLY=1'
  ```

## Straight after

- [ ] Sign in with two accounts and go through the whole flow on production: post, apply, reply, live chat, partners, Workspace.
- [ ] Sign in to `/jobs`, and check that it lists `delete_suspended_accounts` and `send_weekly_check_ins` as recurring.
- [ ] Send a test error from production, and check that it appears in Honeybadger and that the alert email reaches you:

  ```
  bundle exec kamal app exec --reuse --roles=web 'bin/rails runner "Honeybadger.notify(%q(Production test error)); Honeybadger.flush"'
  ```

- [ ] Point Honeybadger's uptime monitor at `https://pairin.dev/health`, and check that it reports the site as up.
- [ ] Request a password reset on production. Check that it reaches the inbox with no warning, the logo shows, the link starts with `https://pairin.dev/`, and the button opens the page to choose a new password.
- [x] *(2026-11-11, to user 12)* Send yourself a copy of the launch email, and read it in your inbox. Use the address of a user on production. Check that the logo shows, and try a non-Gmail address too if you have one:

  ```
  bundle exec kamal app exec --reuse --roles=web 'bin/rails release:send_launch_email TEST_EMAIL=you@example.com'
  ```

- [x] *(2026-11-11: 141 to receive it, 0 opted out, 0 already sent)* See who would get it. This sends nothing:

  ```
  bundle exec kamal app exec --reuse --roles=web 'bin/rails release:send_launch_email'
  ```

- [x] *(2026-11-11, 13:54 UTC: 50 sent, 91 still to send)* Send a first small batch. `APPLY=1` is the step that can't be undone:

  ```
  bundle exec kamal app exec --reuse --roles=web 'bin/rails release:send_launch_email APPLY=1 LIMIT=50'
  ```

- [x] *(2026-11-11, first batch: 1 hard bounce, 3 soft bounces, the rest delivered)* Wait a few hours, then check Mailjet for bounces, blocks and spam reports. You can't see other people's inboxes, so these numbers and any replies are your signal. If they look bad, stop and find out why.
- [x] *(2026-11-11, 17:25 UTC: remaining 91 sent; 141 in total, still to send 0. 1 user opted out between batches)* Repeat with the next batch until `Still to send` is 0. Each run skips anyone already sent to, so nobody gets it twice.
