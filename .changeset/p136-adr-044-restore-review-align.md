---
"@windyroad/itil": patch
---

Align `restore-incident` and `review-problems` with the ADR-044 decision-delegation contract (P136).

- `/wr-itil:restore-incident` now fails fast with a usage message when the incident ID argument is missing or malformed, instead of opening an interactive prompt to backfill it. This matches the `mitigate-incident`, `transition-problem`, and `work-problem` pattern — an argument-shape typo is a re-type, not a decision. The genuine prompts (verification signal, problem handoff) are unchanged.
- `/wr-itil:review-problems` Step 4 now closes verification-pending tickets that already carry cited in-session evidence automatically, mirroring the `run-retro` close-on-evidence path, and reserves the confirmation prompt for tickets with no observed evidence yet. Tickets showing a regression still flip back to known-error and are never batch-closed.
