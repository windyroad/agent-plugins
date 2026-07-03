---
"@windyroad/risk-scorer": patch
---

Graduate changelog changesets for already-shipped verifying fixes (P398)

The held-changeset graduation evaluator no longer strands the changelog entry for a fix that has already shipped. Previously any held changeset whose problem ticket was in Verification Pending was marked `vp-blocked` and never graduated — but a verifying ticket means the code is already live on npm, so only the changelog attribution was held, indefinitely. The evaluator now reads the ticket's `## Fix Released` section: a verifying ticket with a populated section (code shipped) graduates its changelog changeset (`resolved`); a verifying ticket with no such section (fix not yet shipped) stays held (`vp-blocked`). ADR-061 Rule 2 amended to match.
