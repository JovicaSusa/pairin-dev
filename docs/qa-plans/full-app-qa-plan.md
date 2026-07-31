# Pairin — Full-App QA Plan (MVP)

Manual checklist. Regenerate/update this file as the app grows rather than dating each run.

## Setup

- You'll need **two test accounts (A and B)**: A posts a pair request, B sends an offer, so you can exercise the full offer → accept → session flow from both sides.
- Both dev and prod run background jobs on **Solid Queue**, not the inline async adapter — a worker (`bin/jobs`, or whatever the Procfile/dev script starts) must actually be running, or activities never generate and confirmation/session emails never send, even though everything else in the UI looks fine.
- Sign-up requires **email confirmation** (Devise `:confirmable`, `allow_unconfirmed_access_for` not overridden = 0 days). Unlike Swappo, there's **no dev mail viewer here** — `config.action_mailer.delivery_method = :mailjet` even in development (`config/environments/development.rb`), so confirmation and session-scheduled emails go out through the real Mailjet API to a real inbox. Items that require reading the actual email content are tagged **Human** below for this reason.
- Registration has a hidden **honeypot field** (`bot_trap`) — don't fill it when testing normal sign-up, but do test what happens when it's present (see below).
- **Labels**: untagged items are agent-runnable (drive them through a real browser session, not curl). **Human** items are tagged with why — here, mainly "no dev mail viewer, Mailjet sends to a real inbox."

## Landing / Home (`/`)

- [ ] Loads for a signed-out visitor with the marketing copy and sign-up CTA
- [ ] Signed-in visitor hitting `/` behaves sensibly (verify whether it redirects them somewhere more useful, or still renders the marketing page)

## Sign up

- [ ] **Critical** — Valid name/email/password/timezone → account created, user **cannot sign in yet** (unconfirmed) — verifiable without reading the email: sign up, then immediately attempt to sign in and confirm it's blocked
- [ ] **Critical** · **Human** (no dev mail viewer — Mailjet sends to a real inbox) — Confirming via the emailed link → account becomes active, can now sign in
- [ ] Duplicate email → inline validation error, no account created
- [ ] **Important** — Submitting the form with `bot_trap` populated (simulating a bot) → silently redirected to root, **no account created, no error shown** — confirm this is genuinely silent and doesn't leak a "something went wrong" message that would tip off a bot
- [ ] Attempting to sign in with an unconfirmed account → blocked with Devise's "you have to confirm your email address before continuing" message, not a generic login failure

## Sign in

- [ ] **Critical** — Correct credentials, confirmed account → signed in
- [ ] Wrong password → generic invalid-credentials error
- [ ] Unconfirmed account (see above) → confirmation-required message, not signed in

## Profile (`/profiles/show`, update)

- [ ] **Critical** — Update about/programming_since/date_of_birth/country/language/level/profession/name → saved, "You're profile has been updated!"
- [ ] `country` and `language` only accept values from the `I18nData` list — an invalid/tampered value → validation error, not silently accepted
- [ ] `level` only accepts one of `expert/proficient/competent/advanced_beginner/novice` — invalid value rejected
- [ ] Upload a profile image → saved and displayed (via ImageUploader)
- [ ] All profile fields are optional except what's enforced above — confirm you can save with most fields blank (no unexpected "presence" validations beyond the inclusion checks)

## Post a pair request (`/users/pair_requests/new`, create)

- [ ] **Critical** — Subject, description, duration (>0), at least one period (start time), optional tags → created, "Request posted! Good luck", appears in "My pair requests" and in other users' browse list
- [ ] Duration of 0 or negative → validation error
- [ ] Missing subject/description/duration → validation error
- [ ] A period with a start time in the past → validation error ("must be in future") — `end_at` is auto-computed as `start_at + duration`, so also confirm the displayed end time matches
- [ ] Adding a brand-new tag name (not previously used) → tag is created and attached; reusing an existing tag name attaches the existing one, doesn't duplicate it
- [ ] Removing a period/tag via the nested form (`_destroy`) before submitting → not persisted
- [ ] Creating a pair request generates an activity for the requester ("pair_request_created") — confirm it shows up on `/activities`

## Browse pair requests (`/pair_requests`, `/pair_requests/search`)

- [ ] **Critical** — Your own pair requests never appear in the browse list (explicitly excluded — `where.not(user_id: current_user.id)`)
- [ ] Only **active** requests show — one whose only period is in the past should **not** appear (`scope :active` joins on future periods)
- [ ] Search/filter by tag, user, or period narrows results correctly (Ransack on `tags`, `user`, `periods` associations, `duration` attribute)
- [ ] Infinite-scroll pagination (`page` param) loads further pages without duplicating or skipping rows

## Sending an offer (`/pair_requests/:id/offers/new`, create)

- [ ] **Critical** — Pick a period, add a message → offer created, "We have sent your offer, good luck!", both offerer and pair-request owner get an activity (offer_sent / offer_received)
- [ ] Blank message → validation error, offer not created
- [ ] **Critical** — Sending a **second** offer to the same pair request you already offered on → rejected (`pair_request_id` uniqueness scoped to `offerer_id`) — confirm the error is a clear validation message, not a crash
- [ ] Nothing stops you from offering on a request that's already fully booked from the UI layer alone — confirm what actually happens (see "accepted other" status below) rather than assuming it's blocked

## Managing offers on your own request (`/pair_requests/:id/offers`)

- [ ] **Critical** — Only the pair request's owner can view this list (`OfferPolicy#index?`) — the offerer or an unrelated user hitting the URL directly → not authorized, redirected with "Not authorized for this action"
- [ ] Offer status displays correctly per offer: **PENDING** (not accepted, not expired), **EXPIRED** (period's start time has passed, never accepted), **ACCEPTED** (this one), **ACCEPTED OTHER** (a different offer on the same request was accepted)
- [ ] **Critical** — Accepting an offer: only the pair request's owner can accept (`OfferPolicy#accept?`) — the offerer attempting to accept their own offer, or an unrelated user, → not authorized
- [ ] **Critical** — Accepting an offer creates a `Session` at the offer's period times, with **two** participations (the offerer as "pair", the requester as "initiator")
- [ ] **Critical** · **Human** (no dev mail viewer — Mailjet sends to a real inbox) — Both participants actually receive the "session_scheduled_email" after acceptance
- [ ] **Critical** — Accepting one offer generates an "offer_accepted" activity for that offerer, and an "offer_not_accepted" activity for **every other** offerer on the same pair request — confirm all other pending offers are notified, not just left silently stale
- [ ] **Critical** — Attempting to accept a **second** offer on a pair request that already has an accepted offer → fails gracefully ("no longer acceptable"), does **not** create a second session — this is the concurrency guard (`Offers::Accept` checks `has_accepted_offer?` inside a transaction), worth trying with two offers close together to confirm only one wins

## My sent offers (`/users/offers`)

- [ ] Lists only **future** offers (past-period offers drop off this list even if never resolved)
- [ ] Reflects accepted/pending/expired status consistently with what the request owner sees

## Sessions (`/sessions`, update)

- [ ] Lists only **future** sessions for the current user (past sessions drop off)
- [ ] **Critical** — Adding a call link: only the session's "holder" — the pair request's original owner/initiator — can set it (`SessionPolicy#update?` checks `user == sessionable.user`). Confirm the **offerer/pair participant cannot** add or edit the call link even though they're an equal participant in the session — if that's not the intended behavior, it's a real gap, not just a UI omission
- [ ] Call link is required to save an update (`validates :call_link, presence: true, on: :update`) — clearing it and submitting → validation error
- [ ] Saving a call link via `Users::PairRequestsController#add_call_link` (nested `sessions_attributes`) and via `SessionsController#update` are two different paths to the same field — confirm both actually work and don't conflict/race if used interchangeably

## Activities feed (`/activities`)

- [ ] Only shows activities where the current user is the **receiver** — never another user's activities
- [ ] Ordered newest first
- [ ] Spot-check that each trigger above (pair request created, offer sent/received, offer accepted/not-accepted, session scheduled) actually produces the expected entry — this depends on the Solid Queue worker running (see Setup); if activities silently never appear, check the worker before assuming the feature is broken
