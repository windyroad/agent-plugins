---
"@windyroad/itil": patch
---

P347 / ADR-079 Phase 2 — SKILL prose synchronisation (Phase C of the Phase 2 ship).

Synchronises `packages/itil/skills/review-problems/SKILL.md` Step 4.6 prose and `packages/itil/skills/manage-problem/SKILL.md` lifecycle table to the Phase 2 implementation already shipped in this release window (the minor changeset `p347-relevance-close-pass-phase-2.md` covers the script + bats + ADR amendment; this changeset covers the SKILL prose that documents them).

`/wr-itil:review-problems` Step 4.6 now documents the five Phase 1 + Phase 2 evidence shapes (`file-no-longer-exists` / `ADR-shipped-confirmed` / `named-skill-or-feature-exists` / `self-marker-in-body` / `driver-child-ticket-closed`), the Phase 1 false-positive fixes (state-suffix / sibling-file / rename routed to `KEEP-WITH-NOTE`), the `CLOSE-CANDIDATE-WITH-CAVEAT` structured caveat field (architect condition C2), the surface-batch-confirm flow (the methodology that produced today's 14 closes — codified for repeatable use), and the cumulative shape annotation in the `## Closed as no longer relevant` audit-section template per ADR-026.

`/wr-itil:manage-problem` SKILL.md lifecycle-table Closed-row now enumerates the 5 Phase 1 + Phase 2 evidence shapes + names the `CLOSE-CANDIDATE-WITH-CAVEAT` routing through the maintainer's `AskUserQuestion` surface-batch-confirm path, per architect advisory recommendation on Phase 2's cited-shape list.

This is the R002 documentation drift remediation between Phase 2 script behaviour and the SKILL.md prose that documents it.

Closes P347 Phase 2 — Phase C.
