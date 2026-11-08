# Pairin glossary

Pairin connects two people who want to learn together. They talk first, then commit, and arrange how they work together themselves.

Use the words on the left in the UI and in emails. The code keeps its older names for now; a rename follows after launch.

| Word | Meaning | In the code |
|---|---|---|
| **Partner search** | A post saying what someone wants to learn and how long they want to commit | `PairRequest` |
| **Poster** | The person who posted a partner search | `PairRequest#user` |
| **Commitment** | How long a partner search is for: a few weeks, 1–3 months or open-ended | `PairRequest#commitment` |
| **Application** | Someone's answer to a partner search | `Offer` |
| **Applicant** | The person who sent an application | `Offer#offerer` |
| **Partnership** | Two people who agreed to work together on a partner search | `Partnership` |
| **Workspace** | The private page a partnership shares | `PartnershipsController`, `/partners/:id` |
| **Resource** | A link with an optional note that either partner adds to the Workspace | `SharedLink` (`Resource` would clash with the Alba serializers) |
| **Session** | A time a partnership plans to work together. One partner **proposes** it, the other **confirms** or **declines** it, and the proposer can **withdraw** it until then. Either partner can **cancel** a confirmed session before it starts. A proposal nobody answers before it starts has **expired** | `Session` (`status`; expired is worked out, not stored) |
| **Completed session** | A confirmed session that **took place**: after it ends, both partners are emailed "Did it happen?", and it's completed once at least one says Yes. If someone says No and nobody Yes, it **didn't happen** | `Session.completed`, `Session#happened`; answers in `SessionAnswer` |
| **Proposal** | Always say which: a **partnership proposal** (one person in a chat asks to become partners) or a **session proposal** (a session that's been proposed and not yet answered) | `Offer#proposed_at`; `Session#proposed?` |
