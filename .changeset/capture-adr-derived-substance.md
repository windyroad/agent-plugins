---
"@windyroad/architect": minor
---

`/wr-architect:capture-adr` now derives full ADR substance at capture (RFC-045). The deferred-placeholder pattern — `(deferred to /wr-architect:create-adr canonical review)` written into Decision Drivers, Considered Options, Consequences, Confirmation, Pros/Cons, and Reassessment sections — is gone: nothing self-firing ever triggered the canonical expansion, so placeholder sections rotted (P375). The skill now derives real content for every MADR section at capture — genuine drivers, at least two real considered options, Good/Neutral/Bad consequences, testable confirmation criteria, and reassessment criteria — while staying zero-interaction and AFK-safe. Derived substance is recorded `human-oversight: unconfirmed` and ratified at the `/wr-architect:review-decisions` drain surfaced by the SessionStart oversight nudge. `/wr-architect:create-adr` remains the interactive full-intake surface; its role expanding capture skeletons is retired.
