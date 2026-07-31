# Immediate Pairing, Real-Time Discovery, Retro & Public Summaries

## Context

Pairin wants immediately-starting pair requests to become the primary way people find a partner, instead of the current fully-scheduled flow (pick a subject/description/duration, propose candidate time periods, wait for someone to offer, accept later). The reworked flow: a user posts a request that either starts now (with a bounded wait time before they're asked to keep waiting / reschedule / cancel) or is scheduled for later as today; other users see live and scheduled requests separately and can join a live one instantly. Once paired, they go straight to a session — no post-match setup step (an earlier idea to add a wizard here was deliberately dropped in favor of collecting goal/platform/plan at request-creation time, since that also helps joiners choose which request to join). After a session ends, each participant can privately submit an optional retro (a reaction plus free-text learnings/notes/code), and completed sessions become browsable by any logged-in user as a public knowledge base.

This plan implements that end-to-end: schema changes, an instant-join service, two one-time delayed jobs (wait-expiry nag, retro nag), real-time refresh of the "live now" list via the `inertia_cable` gem, and a new public browse page — all following the app's existing conventions (Dry::Operation services, ActivityGeneratable/Activity for in-app notification, parameterized mailers, Pundit policies scoped to route namespaces, Ransack+Pagy+InertiaRails.scroll for browse pages, and the two existing Inertia form idioms — no react-hook-form).

**No session-setup wizard, no `status` enum columns anywhere** — both were explicitly rejected during design. State stays inferred from field presence, matching the existing `call_link.blank?` pattern.

## Critical landmine to fix first

`Period#dates_in_future` and `Session#dates_in_future` both reject `start_at` if `start_at.past?`. Immediate mode creates a `Period`/`Session` with `start_at: Time.current`, which will almost always have ticked into the past by validation time — this fails close to 100% of the time, not as a rare edge case. Fix: change both guards to tolerate a small grace window, e.g. `start_at < 5.seconds.ago`, rather than special-casing `mode` inside the polymorphic `Period`/`Session` models.

## 1. Migrations

- `AddModeAndScheduleFieldsToPairRequests`: on `pair_requests` add `mode` (string, `null: false, default: "scheduled"`), `wait_minutes` (integer, nullable), `requires_approval` (boolean, `null: false, default: false`), `goal` (text), `platform` (string), `pairing_tool` (string), `plan` (text). Index on `mode`.
- `CreateSessionFeedbacks`: new table `session_feedbacks` — `session_id` (FK to sessions), `participant_id` (FK to users), `went_well` (string), `learned` (text), `notes` (text), `code_snippet` (text), `code_snippet_language` (string). Unique index on `[session_id, participant_id]`.
- No migration for a persisted "summary" — it's a read-time join of `Session` → `sessionable` (`PairRequest`) → `session_feedbacks`, per the "keep it simple" steer.

## 2. Model changes

**`app/models/pair_request.rb`**
- `MODES = %w(immediate scheduled)`, `PLATFORMS = %w(...)` (string-array constants, matching `User::LEVELS` convention — not a native Rails enum, nothing else in the app uses one).
- Validations: `mode` inclusion, `wait_minutes` inclusion in `[15, 30, 60, 120]` (`allow_nil`), `platform` inclusion (`allow_blank` if "other" free text is allowed).
- Scopes: `scope :scheduled_active` (today's `active` scope, renamed/scoped to `mode: "scheduled"`), `scope :live_now` (mode immediate, joins periods, `periods.start_at + wait_minutes minutes > now`, excludes already-matched via `has_accepted_offer?`/an offers join).
- Nested `periods_attributes`/`taggings_attributes` stay; the controller only honors client-sent periods for `mode: "scheduled"` — immediate mode builds its own single `Period` server-side.

**New `app/models/session_feedback.rb`**: `belongs_to :session`, `belongs_to :participant, class_name: "User"`, `WENT_WELL_VALUES` constant, inclusion + uniqueness (`participant_id` scoped to `session_id`) validations. All fields optional — retro stays fully optional.

**`app/models/session.rb`**: `has_many :session_feedbacks, dependent: :destroy`; helpers `feedback_from(participant)`, `feedback_complete?`. Apply the grace-window fix from the landmine section.

**`app/models/user.rb`**: `has_many :session_feedbacks, foreign_key: :participant_id`.

## 3. Service objects (Dry::Operation, mirroring `app/services/offers/accept.rb`)

- **`app/services/pair_requests/instant_join.rb`** — the no-approval join path. Inside a transaction: lock the `PairRequest` row (`PairRequest.lock.find(id)` — see race-condition note below), fail if already matched or `requires_approval?`, build an `Offer` (default message, the immediate period), then call the existing `Offers::Accept.call(offer)` to reuse session/participation/mailer logic unchanged.
  - **Race condition to resolve before shipping**: the existing `has_accepted_offer?` check inside `Offers::Accept#validate` plus the `[offerer_id, pair_request_id]` unique index on `offers` prevents the *same* user double-joining, but does **not** stop two *different* users both passing that check before either commits, under Postgres's default READ COMMITTED isolation. Instant-join is the first flow where strangers race for the same `PairRequest` in the same instant, so add `PairRequest.lock.find(...)` inside `InstantJoin`'s transaction as the minimal fix.
- **`app/services/pair_requests/extend_wait.rb`** — "continue waiting": bumps the immediate period's `start_at` to now, re-enqueues the expiry job.
- **`app/services/pair_requests/reschedule.rb`** — "reschedule": flips `mode` to `scheduled`, replaces the period via the same `periods_attributes` shape the existing create form already accepts (reuse the period-picker UI, don't build a new one).
- **Cancel**: no new service — a plain `destroy` action on `Users::PairRequestsController`, consistent with there being no soft-cancel/cancelled state anywhere else in the app.

## 4. Jobs — one-time delayed jobs, not recurring

Both use `SomeJob.set(wait_until: ...).perform_later(record)` (solid_queue supports this natively). `config/recurring.yml` stays untouched/commented out — these are per-record delayed jobs, not cron polls. Both re-check current state at execution time rather than trusting enqueue-time state, since the record can change during the wait.

- **`app/jobs/pair_requests/immediate_expiry_job.rb`**: no-ops if the pair_request is destroyed, already matched, or no longer `mode: "immediate"` (guards against a stale enqueue after a reschedule). Otherwise creates an `Activity` directly (`Activity.create!(receiver:, title:, content:)`, matching the pattern in `ActivitiesSetup::FromParticipation` — this is job-initiated, not `previous_changes`-driven, so it doesn't need a new `ActivitiesSetup::From*` dispatcher class) and sends a new mailer. Scheduled from `Users::PairRequestsController#create` right after a successful immediate-mode save (not a model callback — model callbacks here are reserved for the `ActivityGeneratable` pipeline).
- **`app/jobs/session_feedback_nag_job.rb`**: no-ops if the session is destroyed; otherwise, for each participant missing feedback, creates an `Activity` + sends a nag mailer. Scheduled from `Offers::Accept#schedule_session` right after `Session.create!`, at `session.end_at + 5.minutes` — co-located with where `SessionMailer` is already triggered in that same service.

## 5. Mailers & Activity content

- New `app/mailers/pair_request_mailer.rb` with `immediate_expired_email` (parameterized `.with(pair_request:, user:)`).
- `app/mailers/session_mailer.rb` gains `retro_nag_email` (`.with(session:, participant:)`).
- Both follow the existing parameterized-mailer pattern (`ApplicationMailer` subclass, triggered via `.deliver_later` from a service/job, not a model or controller directly).
- New locale keys under `en.activities.retro_nag` / `en.activities.immediate_expired` in `config/locales/activities/en.yml`, matching the sampled-copy convention every other activity type uses.
- New mailer previews in `spec/mailers/previews/`, matching the existing preview file pattern.

## 6. Controllers, routes, policies

**`config/routes.rb`** additions:
```ruby
resources :pair_requests, only: [:index] do
  scope module: 'pair_requests' do
    resources :offers, only: [:index, :new, :create] do
      post "accept", on: :member
    end
    resource :join, only: [:create], controller: "joins"   # new
  end
  get :search, on: :collection
end

resources :session_summaries, only: [:index]                # new

namespace :users do
  resources :pair_requests, expect: [:edit, :update] do
    patch :add_call_link, on: :member
    patch :extend_wait, on: :member    # new
    patch :reschedule, on: :member     # new
    # :destroy already included by `expect: [:edit, :update]` — used for "cancel"
  end
  resources :offers, only: [:index]
end

resources :session_feedbacks, only: [:new, :create]          # new
```

**`PairRequestsController#index`** (public browse): split into two separately-keyed props — `livePairRequests` (from `live_now`, no pagination needed given it's meant to be small/transient) and `scheduledPairRequests` (today's Ransack+Pagy+`InertiaRails.scroll` flow, unchanged apart from the `scheduled_active` scope rename). Add `liveCableStream: inertia_cable_stream("pair_requests_live")`. Keep serialization consistent with how this controller already renders (`.as_json` with `include:`, since — unlike `Users::PairRequestsController` — it doesn't use `Alba::Inertia::Controller`).

**New `app/controllers/pair_requests/joins_controller.rb`**: `create` finds the `PairRequest`, authorizes via a new `PairRequests::JoinPolicy` (`create? = record.user != user && record.mode == "immediate" && !record.requires_approval?`), calls `PairRequests::InstantJoin.call`, redirects to sessions on success / back with an alert on failure (mirrors `PairRequests::OffersController#accept`'s `.either(...)` pattern). When `requires_approval?` is true, the frontend renders the existing "Apply" flow instead — reuses `PairRequests::OfferPolicy` unchanged, no new policy needed for that branch.

**`Users::PairRequestsController`**:
- `pair_request_params` gains `:mode, :wait_minutes, :requires_approval, :goal, :platform, :pairing_tool, :plan`.
- `create`: for `mode: "immediate"`, override any client-sent periods with a single `{ start_at: Time.current }`, and after a successful save, schedule `PairRequests::ImmediateExpiryJob` at `period.start_at + wait_minutes.minutes`.
- New `destroy`, `extend_wait`, `reschedule` actions, each `authorize`d via `Users::PairRequestPolicy` (gains `destroy?`, `extend_wait?`, `reschedule?` predicates — `user == record.user`, matching the existing terse-predicate style).
- `index` needs **no change** — it already scopes on `current_user.pair_requests` with no future/active filtering, so an expired-and-unactioned immediate request already surfaces there for the requester to act on. Confirmed by reading the controller.

**New `app/controllers/session_summaries_controller.rb`**: public browse of completed sessions. To avoid Ransack traversing the polymorphic `Session.sessionable` association (which it doesn't do cleanly), **query from `PairRequest` outward** — reuse its existing `ransackable_associations`/`ransackable_attributes` unchanged, scoped to pair requests with a past-`end_at` session, `.includes(sessions: :session_feedbacks)`. Same Ransack+Pagy+`InertiaRails.scroll` shape as `PairRequestsController#index`.

## 7. Frontend changes

- **`app/javascript/pages/Users/PairRequests/New.jsx`**: add a `mode` toggle (two-button toggle group using the existing `Button` component — no new shadcn dependency needed for a binary choice). Scheduled mode keeps today's periods fieldset unchanged; immediate mode hides it and shows `wait_minutes` (`Select`, options 15/30/60/120, same pattern as `Offers/New.jsx`'s period select) and a `requires_approval` toggle (same two-button pattern). Add `goal` (`Textarea`), `platform` (`Select`, options passed as a prop like `userLevels`/`languages` are today), `pairing_tool` (`Input`, optional), `plan` (`Textarea`, optional) — all flat fields on the existing `useForm` `data` object, no array-handling needed.
- **`app/javascript/pages/PairRequests/Index.jsx`**: split into a "Live now" section (`livePairRequests`, wired to `useInertiaCable(liveCableStream, { only: ['livePairRequests'] })` from `@inertia-cable/react`) and the existing "Scheduled" section (renamed prop, Collapsible+FilterForm+InfiniteScroll block otherwise unchanged).
- **`app/javascript/pages/PairRequests/Card.jsx`**: accepts a `live` prop — when true and `!requires_approval`, renders a "Join" button (`<Form method="post" action=".../join">`, the render-prop idiom used for single-action posts like `Sessions/Card.jsx`'s call-link form) instead of the "Apply" `Link`.
- **New `app/javascript/pages/SessionFeedbacks/New.jsx`**: retro form, `<Form>` render-prop pattern (uncontrolled, single POST). `went_well` as an emoji-button row (local `useState` + hidden input, same technique `Offers/New.jsx` already uses for its period selection), plus `Textarea`s for `learned`/`notes`/`code_snippet` and an input for `code_snippet_language`.
- **New `app/javascript/pages/SessionSummaries/Index.jsx` + `Card.jsx`**: near copy of `PairRequests/Index.jsx`/`Card.jsx`'s browse shell; `Card` renders the pair request's `subject`/`description`/`goal`/`platform`/`plan`/`tags` plus both `session_feedbacks` (emoji + text) side by side.
- **`package.json`**: add `@inertia-cable/react` and `@rails/actioncable`.

## 8. Gems / infra

- `Gemfile`: `gem "inertia_cable"` (the published gem name — hyphenated form is only the repo/npm scope), then `bundle install` and `rails generate inertia_cable:install`.
- `PairRequest` includes `InertiaCable::Broadcastable`: `broadcasts_to "pair_requests_live", on: [:create, :update, :destroy], if: -> { mode == "immediate" || mode_previously_was?("immediate") }` — the `if:` guard keeps scheduled-mode churn from spuriously refreshing the live list, and also catches the "reschedule" transition out of immediate mode so the card disappears for everyone.
- `config/cable.yml` (redis dev/prod, test adapter) and ActionCable's default `/cable` mount already exist — no changes needed there.
- `npm install @inertia-cable/react @rails/actioncable`.

## 9. Build/ship sequence

1. **Schema + models** — both migrations, model changes, the `dates_in_future` grace-window fix. Fully testable in isolation, nothing user-visible yet.
2. **Immediate-mode create, no real-time yet** — form + controller changes, `live_now`/`scheduled_active` scopes, the two-prop index split (manual refresh only). Shippable: users can post and see immediate requests.
3. **Instant join + expiry job** — `InstantJoin`, `JoinsController`/`JoinPolicy`, `ImmediateExpiryJob` + mailer, `extend_wait`/`reschedule`/`destroy`. Resolve the row-locking question here before shipping. Fully testable via request/service specs, no JS work needed.
4. **Real-time layer** — `inertia_cable` gem/npm install, `broadcasts_to`, `useInertiaCable` wiring. Purely additive on top of step 3; step 3's manual-refresh UX still works if this needs to be pulled.
5. **Retro + nag job** — `SessionFeedback` model (already migrated in step 1), controller/form, `SessionFeedbackNagJob` + mailer, scheduling hook in `Offers::Accept`. Independent of steps 2–4.
6. **Public summary browse page** — depends on step 5's data, not on 2–4 (works for any completed session).

Steps 1 and 5 have no dependency on 2–4 and can be built in parallel.

## Open questions (flagged, not silently resolved)

1. `PLATFORMS` exact value list, and whether the `requires_approval` boolean should get a real shadcn checkbox vs. the two-button toggle reuse — small product/design call.
2. Whether `SessionFeedback` submission should itself generate an Activity for the other participant ("your partner left feedback") — not in the original scope; possible v1.1.

## Critical files

- `app/models/pair_request.rb`, `app/models/period.rb`, `app/models/session.rb`, `app/models/offer.rb`
- `app/services/offers/accept.rb` (pattern to mirror for `InstantJoin`)
- `app/controllers/pair_requests_controller.rb`, `app/controllers/users/pair_requests_controller.rb`, `app/controllers/pair_requests/offers_controller.rb`
- `app/models/concerns/activity_generatable.rb`, `app/services/activities_setup/from_offer.rb` (Activity pattern reference)
- `app/javascript/pages/PairRequests/Index.jsx`, `Card.jsx`, `app/javascript/pages/Users/PairRequests/New.jsx`, `app/javascript/pages/Sessions/Card.jsx` (call-link form pattern to mirror)
- `config/routes.rb`

## Verification

- `bundle exec rspec` for the new/changed model, service, job, mailer, and request specs (factories extended with `immediate`/`requires_approval` traits, mirroring `spec/services/offers/accept_spec.rb`'s structure for `InstantJoin`).
- Manually exercise the golden path in the browser: create an immediate request as one user, join it as another (instant, no approval) → confirm a `Session` is created and both land on `Sessions#index`; create one with `requires_approval: true` and confirm it falls back to the existing offer/accept flow unchanged.
- Let an immediate request's `wait_minutes` elapse (or trigger the job manually via `rails runner`) and confirm the Activity + email fire once, and the request drops out of the public live list but still shows in the requester's own list with continue/reschedule/cancel actions.
- After a session's `end_at` passes, confirm the retro nag fires once, submit feedback as both participants, and confirm the session appears correctly on the new public summary browse page with both reactions/notes visible.
- Open two browser sessions to confirm the "Live now" list on one auto-refreshes (via `inertia_cable`) when the other creates/joins/cancels an immediate request, without a manual page reload.
