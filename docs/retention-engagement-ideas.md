# Retention & Engagement Ideas

## Context

While scoping the "Wall" feature (a public tweet-like feed — see the Wall issues in the tracker, filed as a vertical-slice breakdown), we flagged a risk: a feed feature is only as good as its content density. For an early-stage app with a small user base, an empty or sparse Wall risks feeling more dead than no Wall at all, undercutting the "feels alive" goal it's meant to serve.

That prompted a broader brainstorm: what could keep users returning to the app that **doesn't depend on other users' activity or a critical mass of content**? The ideas below are grouped by mechanism, from safest/cheapest to more involved.

## Personal progress (pure gamification, zero network effect)

Value comes entirely from the user's own history — works identically whether they're the only active user or one of thousands.

- **Pairing streak + stats dashboard** — sessions this week/month, total hours paired, languages/partners paired with. Derivable from existing `Session`/`Participation` data, no new schema needed for the core numbers.
- **Contribution-graph-style calendar heatmap** on the profile page — a GitHub-style grid of "days you paired." Visually satisfying, personal, reuses data already captured.
- **Badges/achievements** — "first session," "5 sessions," "paired in 3 languages," "night owl (paired after 10pm)." Trigger off `Session`/`Participation` counts, fire an `Activity` (and optionally an email) on unlock. Cheap to build incrementally — start with 3-4 badges.
- **"My Learnings" personal retro timeline** — a private version of the public session-summaries page, scoped to just the current user: every `learned`/`notes` field they've written across past retros, browsable/searchable. Useful even as a lone active user.

## Re-engagement nudges (push, not pull — doesn't need feed content)

- **Inactivity win-back job** — "You haven't paired in 2 weeks — here's what's open right now" digest email, scheduled off last-session timestamp. Single highest-leverage retention lever independent of user count, because it's push-based rather than relying on the user finding something on their own.
- **Saved search / alert** — "notify me when a Python pair request opens" so users don't have to babysit the browse page. Doubles as a matching-liquidity improvement at low volume, not just a retention play.
- **Goal reminders** — user sets "pair 2x this week," gets a nudge mid-week if they're behind. Simple cron job + their own data, no dependency on others.

## Content-independent "something to do" (higher build cost, works with one user online)

- **Daily/weekly coding kata or discussion prompt** — unrelated to matching, gives a reason to open the app solo. Needs a content source (curated list or generator) — more effort than the personal-progress ideas.
- **GitHub streak integration** — OAuth in, show commit streak, nudge "your streak's at risk, pair today?" Compelling but a real integration project (OAuth, API polling), not a quick win.

## Recommendation

Build the **inactivity win-back email** next: a single job + one mailer, no new schema required, and it directly attacks the "will they come back" problem better than anything content-based, since it doesn't rely on there being anything interesting on the app yet.

Wall itself (public feed) should stay queued but deferred until there's a critical mass of active users to seed it — see `immediate-pairing-implementation-plan.md` for the currently-in-progress work it's sequenced behind.
