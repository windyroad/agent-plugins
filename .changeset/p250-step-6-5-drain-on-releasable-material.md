---
"@windyroad/itil": patch
---

**P250**: `/wr-itil:work-problems` Step 6.5 release-cadence classification now drains on **presence of releasable material**, not on residual band reaching appetite. The defective prior clause `Within appetite (≤ 3/25) — no drain needed` encoded accumulation-permitted-below-threshold semantics that violated the symmetric-balance principle (ADR-061 Rule 1) and the user's release principle.

**New three-band classification**:

- **Above appetite (≥ 5/25)** — route to ADR-042 auto-apply (unchanged).
- **Within appetite (≤ 4/25) AND releasable material** (any unpushed commits OR any `.changeset/` entries OR any graduation-eligible held entries per ADR-061 Rule 1) — drain via `push:watch` then, if releasable changesets exist, `release:watch`.
- **Within appetite (≤ 4/25) AND empty queue** (no unpushed commits AND no `.changeset/` AND no graduation-eligible held entries) — no drain (literally nothing to release).

The residual band remains the safety check (above-appetite never releases); the within-appetite branch is now an action gate driven by presence of releasable material. ADR-018 amended in same commit per ADR-014 single-unit-of-work.

User-direction citation (P250 Description): *"You don't want to accumulate risk. If it's low risk, you should release."*
