---
"@windyroad/itil": minor
---

Rate problem and story captures at capture time instead of deferring them.

`capture-problem` and `capture-story` now derive a real rating from the description at capture — `capture-problem` derives Impact × Likelihood and Effort, `capture-story` derives Effort — as one silent inference, no extra prompts. They no longer stamp a `(deferred — re-rate at next review)` placeholder.

The old default was the largest source of stale backlog: it minted a false-low (`Likelihood: 1`) that buried every fresh capture at the bottom of the WSJF queue, plus a "re-rate later" deferral that nothing automatically triggered, so the re-rate rarely happened. A rough estimate from a thin description is honest estimation; `/wr-itil:review-problems` still re-rates the whole backlog when it runs.

Captures of an architecture decision (`capture-adr`) keep deferring their human-judgment sections (the canonical options and consequences are yours to author) — those are surfaced by the deferral census rather than guessed at.

Substance recorded as an amendment to ADR-032; driver P375.
