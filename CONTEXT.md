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
| **Partnership** | Two people who agreed to work together on a partner search | Not built yet (#169) |
| **Workspace** | The private page a partnership shares | Not built yet (#185) |
| **Resource** | A link with an optional note that either partner adds to the Workspace | `SharedLink` (`Resource` would clash with the Alba serializers) |
